# frozen_string_literal: true

module PhlexLint
  module Rules
    # Enforce use of design system classes only.
    #
    # Following ITCSS (Inverted Triangle CSS) principles, classes in the
    # component layer should be limited to:
    # 1. Design tokens (gm-*)
    # 2. Bootstrap utilities (for layout: d-*, m-*, p-*, gap-*, etc.)
    # 3. Component-specific classes (handled by component parameters)
    #
    # Custom ad-hoc classes (my-widget, status-box) create design debt.
    # Use the design system or create a new component instead.
    #
    # @example Bad
    #   div(class: "my-widget")
    #   span(class: "status-box active")
    #   p(class: "custom-text")
    #
    # @example Good
    #   div(class: "gm-mt-4")
    #   FlexRow(gap: :md)
    #   Text(color: :muted)
    class NoCustomClasses < Rule
      category "ITCSS"

      # Design token prefix pattern (gm-* current tokens, lgm-* legacy tokens)
      GM_TOKEN_PATTERN = /\A[lg]?gm-/

      # Comprehensive Bootstrap 5 utility pattern.
      # Covers: display, flex, grid, spacing (margin/padding with s/e for start/end),
      # sizing, typography, colors, borders, positioning, opacity, visibility, etc.
      BOOTSTRAP_UTILITY_PATTERN = /\A(
        d-(none|inline|inline-block|block|grid|inline-grid|table|table-row|table-cell|flex|inline-flex|
           sm-[a-z-]+|md-[a-z-]+|lg-[a-z-]+|xl-[a-z-]+|xxl-[a-z-]+) |
        gap-\d+                                                        |
        [gG][xy]?-\d+                                                  |
        [mp][tblrxyse]?-(?:n?\d+|auto)                                 |
        [mp][tblrxyse]?-(?:sm|md|lg|xl|xxl)-(?:n?\d+|auto)            |
        w-(?:\d+|auto|100)                                             |
        h-(?:\d+|auto|100)                                             |
        mw-100|mh-100|min-vw-100|min-vh-100|vw-100|vh-100             |
        text-(?:start|end|center|wrap|nowrap|break|lowercase|uppercase|capitalize|
               decoration-none|decoration-underline|reset|truncate|
               muted|primary|secondary|success|danger|warning|info|light|dark|
               body|white|black-50|white-50|opacity-\d+|
               [a-z]+-emphasis|
               sm-[a-z]+|md-[a-z]+|lg-[a-z]+|xl-[a-z]+)              |
        bg-(?:primary|secondary|success|danger|warning|info|light|dark|
             body|white|transparent|opacity-\d+|gradient)              |
        fw-(?:bold|bolder|semibold|medium|normal|light|lighter|\d+)    |
        fs-[1-6]                                                       |
        fst-(?:italic|normal)                                          |
        lh-(?:1|sm|base|lg)                                            |
        font-monospace                                                 |
        rounded(?:-(?:top|end|bottom|start|circle|pill|0|1|2|3|4|5))?  |
        border(?:-(?:top|end|bottom|start|0|1|2|3|4|5|
                    primary|secondary|success|danger|warning|info|light|dark|white))? |
        align-(?:items|self|content)-(?:start|end|center|baseline|stretch) |
        justify-content-(?:start|end|center|between|around|evenly)     |
        flex-(?:row|column|row-reverse|column-reverse|wrap|nowrap|
               wrap-reverse|fill|grow-[01]|shrink-[01]|
               sm-[a-z-]+|md-[a-z-]+|lg-[a-z-]+|xl-[a-z-]+)          |
        order-(?:first|last|\d+)                                       |
        float-(?:start|end|none|sm-[a-z]+|md-[a-z]+|lg-[a-z]+)       |
        position-(?:static|relative|absolute|fixed|sticky)             |
        top-(?:0|50|100)                                               |
        bottom-(?:0|50|100)                                            |
        start-(?:0|50|100)                                             |
        end-(?:0|50|100)                                               |
        translate-middle(?:-[xy])?                                     |
        overflow-(?:auto|hidden|visible|scroll)                        |
        overflow-[xy]-(?:auto|hidden|visible|scroll)                   |
        shadow(?:-(?:sm|lg|none))?                                     |
        opacity-(?:0|25|50|75|100)                                     |
        visible|invisible                                              |
        visually-hidden(?:-focusable)?                                 |
        clearfix                                                       |
        ratio|ratio-\w+                                                |
        object-fit-(?:contain|cover|fill|scale|none)                   |
        col(?:-(?:\d+|auto|sm-\d+|md-\d+|lg-\d+|xl-\d+|xxl-\d+|
                 sm-auto|md-auto|lg-auto|xl-auto|xxl-auto))?          |
        row(?:-cols-(?:\d+|auto|sm-\d+|md-\d+|lg-\d+|xl-\d+))?      |
        container(?:-(?:sm|md|lg|xl|xxl|fluid))?                       |
        img-(?:fluid|thumbnail)                                        |
        list-(?:unstyled|inline|inline-item|group|group-item|
               group-flush|group-numbered|group-horizontal)            |
        blockquote|blockquote-footer                                   |
        lead|mark|small|initialism                                     |
        h[1-6]                                                         |
        display-[1-6]                                                  |
        page-link|page-item                                            |
        sr-only|sr-only-focusable                                      |
        stretched-link                                                 |
        hstack|vstack                                                  |
        user-select-(?:all|auto|none)                                  |
        pe-(?:none|auto)                                               |
        input-group(?:-text|-sm|-lg)?                                  |
        form-(?:label|control|control-sm|control-lg|control-plaintext|
               select|select-sm|select-lg|check|check-input|check-label|
               switch|range|floating|text)                             |
        invalid-feedback|valid-feedback                                |
        was-validated                                                  |
        btn(?:-(?:primary|secondary|success|danger|warning|info|light|dark|
                 link|outline-primary|outline-secondary|outline-success|
                 outline-danger|outline-warning|outline-info|outline-light|
                 outline-dark|sm|lg|close|group|toolbar))?             |
        card(?:-(?:header|body|footer|title|subtitle|text|link|
                  img-top|img-bottom|img-overlay|group))?              |
        table(?:-(?:striped|hover|bordered|borderless|responsive|
                   sm|dark|light|active|primary|secondary|success|
                   danger|warning|info))?                              |
        alert(?:-(?:primary|secondary|success|danger|warning|info|
                   light|dark|link|heading|dismissible))?              |
        badge(?:-(?:primary|secondary|success|danger|warning|info))?   |
        nav(?:-(?:tabs|pills|fill|justified|link|item))?               |
        navbar(?:-(?:brand|toggler|toggler-icon|collapse|nav|text|
                    expand|expand-sm|expand-md|expand-lg|expand-xl|
                    light|dark))?                                      |
        dropdown(?:-(?:toggle|menu|menu-end|menu-start|item|
                     header|divider))?                                 |
        modal(?:-(?:dialog|dialog-centered|dialog-scrollable|
                   content|header|title|body|footer|sm|lg|xl|
                   fullscreen(?:-[a-z]+-down)?))?                      |
        collapse|collapsing|show|hide|fade                             |
        accordion(?:-(?:item|header|button|body|collapse|flush))?      |
        tab-content|tab-pane                                           |
        spinner(?:-(?:border|border-sm|grow|grow-sm))?                 |
        carousel(?:-(?:item|inner|control-prev|control-next|
                     indicators|caption|dark|fade))?                   |
        breadcrumb(?:-item)?                                           |
        pagination(?:-(?:sm|lg))?                                      |
        placeholder(?:-(?:glow|wave|xs|sm|lg))?                        |
        progress(?:-bar)?                                              |
        toast(?:-(?:container|header|body))?                           |
        tooltip|popover                                                |
        offcanvas(?:-(?:start|end|top|bottom|body|header|title))?      |
        white-space-(?:normal|nowrap|pre|pre-line|pre-wrap)              |
        active|disabled|show|fade|collapsed                            |
        fixed-(?:top|bottom)                                           |
        sticky-(?:top|bottom|sm-top|md-top|lg-top|xl-top)
      )\z/x

      # Application component-layer CSS classes defined in styles.css.
      # These are legitimate component styles, not ad-hoc custom classes.
      # Organized by ITCSS component layer (molecules, organisms, utilities).
      APP_CSS_PATTERN = /\A(
        modal-[a-z-]+                                                      |
        info-(?:card|row|icon|tooltip)[a-z-]*                               |
        auth-[a-z-]+                                                       |
        data-(?:row|card|cell|label|value|header|meta)[a-z-]*              |
        form-section(?:-[a-z-]+)?                                          |
        section-(?:card|header|content|title|divider)[a-z-]*               |
        expanded-(?:cards|content|header|tiles)[a-z-]*                     |
        indicator-[a-z-]+                                                  |
        nav-(?:item-content|label|section|divider)[a-z-]*                  |
        pagination-[a-z-]+                                                 |
        glass-(?:card|panel|container|surface)[a-z-]*                      |
        detail-[a-z-]+                                                     |
        priority-target[a-z-]*                                             |
        welcome-section                                                    |
        introduction-step                                                  |
        notes-label                                                        |
        invitation-[a-z-]+                                                 |
        sidebar-[a-z-]+                                                    |
        pricing-[a-z-]+                                                    |
        wizard-[a-z-]+                                                     |
        row-avatar[a-z-]*                                                  |
        value-[a-z-]+                                                      |
        region-[a-z-]+                                                     |
        analytics-[a-z-]+                                                  |
        profile-[a-z-]+                                                    |
        source-icon                                                        |
        event-[a-z-]+                                                      |
        meta-line                                                          |
        readiness-[a-z-]+                                                  |
        tile-[a-z-]+                                                       |
        rejection-[a-z-]+                                                  |
        task-(?:modal|form|card|item|meta|header)[a-z-]*                   |
        action-type-[a-z-]+                                                |
        warmth-[a-z-]+                                                     |
        buying-window-[a-z-]+                                              |
        snapshot-[a-z-]+                                                   |
        criterion-[a-z-]+                                                  |
        company-[a-z-]+                                                    |
        product-[a-z-]+                                                    |
        compound-pattern-[a-z-]+                                           |
        risk-factor-[a-z-]+                                                |
        enrichment-[a-z-]+                                                 |
        onboarding-[a-z-]+                                                 |
        config-[a-z-]+                                                     |
        footer-[a-z-]+                                                     |
        intro-[a-z-]+                                                      |
        score-[a-z-]+                                                      |
        scoring-[a-z-]+                                                    |
        agent-chat-[a-z-]+                                                 |
        chat-[a-z-]+                                                       |
        message-[a-z-]+                                                    |
        stakeholder-[a-z-]+                                                |
        pitch-[a-z-]+                                                      |
        gdpr-[a-z-]+                                                       |
        compliance-[a-z-]+                                                 |
        subscription-[a-z-]+                                               |
        addon-[a-z-]+                                                      |
        industry-[a-z-]+                                                   |
        search-[a-z-]+                                                     |
        discovery-[a-z-]+                                                  |
        briefing-[a-z-]+                                                   |
        timeline-[a-z-]+                                                   |
        email-[a-z-]+                                                      |
        automation-[a-z-]+                                                 |
        webhook-[a-z-]+                                                    |
        integration-[a-z-]+                                                |
        key-[a-z-]+                                                        |
        confidence-[a-z-]+                                                 |
        org-chart-[a-z-]+                                                  |
        nav-(?:btn|icon)[a-z-]*                                            |
        legend-[a-z-]+                                                     |
        source-[a-z-]+                                                     |
        typing-[a-z-]+                                                     |
        info-(?:icon|tooltip)[a-z-]*                                       |
        radar-[a-z-]+                                                      |
        follow-[a-z-]+                                                     |
        three-way-toggle[a-z_-]*                                           |
        button-(?:text|container|icon)[a-z-]*                              |
        activity-[a-z-]+                                                   |
        influence-[a-z-]+                                                  |
        account-option[a-z-]*                                              |
        date-(?:info|icon|label)[a-z-]*                                    |
        list-item-[a-z-]+                                                  |
        stat-[a-z-]+                                                       |
        autocomplete-[a-z-]+                                               |
        form-(?:grid|help|label|input|badge|count)[a-z-]*                  |
        card-(?:icon|header-icon|content|title|badge)[a-z-]*               |
        contact-[a-z-]+                                                    |
        language-[a-z-]+                                                   |
        select-[a-z-]+                                                     |
        weight-[a-z-]+                                                     |
        criteria-[a-z-]+                                                   |
        progress-[a-z-]+                                                   |
        banner-[a-z-]+                                                     |
        chart-[a-z-]+                                                      |
        career-[a-z-]+                                                     |
        feature-[a-z-]+                                                    |
        addon-[a-z-]+                                                      |
        api-key[a-z-]*                                                     |
        provider-[a-z-]+                                                   |
        platform-[a-z-]+                                                   |
        usage-[a-z-]+                                                      |
        limit-[a-z-]+                                                      |
        link-[a-z-]+                                                       |
        meter-[a-z-]+                                                      |
        switch-[a-z-]+                                                     |
        icon-[a-z-]+                                                       |
        content-[a-z-]+                                                    |
        header-[a-z-]+                                                     |
        step-[a-z-]+                                                       |
        status-[a-z-]+                                                     |
        label-[a-z-]+                                                      |
        field-[a-z-]+                                                      |
        account-selector[a-z-]*                                            |
        prospect-[a-z-]+                                                   |
        prospects-[a-z-]+                                                  |
        row-[a-z-]+                                                        |
        outreach-[a-z-]+                                                   |
        empty-(?:state|chart)[a-z-]*                                       |
        stage-[a-z-]+                                                      |
        apc-[a-z-]+                                                        |
        kp-[a-z-]+                                                         |
        sm-[a-z-]+                                                         |
        persona-[a-z-]+                                                    |
        radar-chart[a-z-]*                                                 |
        buying-[a-z-]+                                                     |
        tooltip-[a-z-]+                                                    |
        playbook-[a-z-]+                                                   |
        queue-[a-z-]+                                                      |
        draft-[a-z-]+                                                      |
        alert-[a-z-]+                                                      |
        risk-[a-z-]+                                                       |
        navbar-[a-z-]+                                                     |
        suggestion-[a-z-]+                                                 |
        oauth-[a-z-]+                                                      |
        tab-[a-z-]+                                                        |
        login-[a-z-]+                                                      |
        social-[a-z-]+                                                     |
        trial-[a-z-]+                                                      |
        plan-[a-z-]+                                                       |
        setup-[a-z-]+                                                      |
        domain-[a-z-]+                                                     |
        tenant-[a-z-]+                                                     |
        context-bar[a-z-]*                                                 |
        register-[a-z-]+                                                   |
        bg-summary-[a-z_-]+                                                |
        danger-(?:zone|action|warning)[a-z-]*                              |
        form-group[a-z_-]*                                                 |
        kvk-[a-z-]+                                                        |
        maturity-[a-z-]+                                                   |
        mobile-nav[a-z-]*                                                  |
        cached-content[a-z-]*                                              |
        relevance-[a-z-]+                                                  |
        significance-[a-z-]+                                               |
        metadata-[a-z-]+                                                   |
        indicators-[a-z-]+                                                 |
        user-avatar[a-z-]*                                                 |
        heatmap-[a-z-]+                                                    |
        advice-carousel[a-z-]*                                             |
        configuration-card                                                 |
        entity-[a-z-]+                                                     |
        impersonation-banner[a-z-]*                                        |
        integrations-[a-z-]+                                               |
        kanban-[a-z-]+                                                     |
        main-content                                                       |
        simple-onboarding-[a-z-]+                                          |
        turbo-confirm-[a-z-]+                                              |
        notable-[a-z-]+                                                    |
        role-[a-z-]+                                                       |
        overflow-[a-z-]+                                                   |
        loading-state                                                      |
        error-state                                                        |
        changelog-[a-z-]+                                                  |
        password-[a-z-]+                                                   |
        toggle-[a-z-]+                                                     |
        price-[a-z-]+                                                      |
        breadcrumb-[a-z-]+                                                 |
        checkbox-[a-z-]+                                                   |
        copy-[a-z-]+                                                       |
        description-text                                                   |
        card-[a-z-]+                                                       |
        globe-icon                                                         |
        menu-[a-z-]+                                                       |
        url-[a-z-]+                                                        |
        summary-[a-z-]+                                                    |
        calendar-icon                                                      |
        heading-[a-z-]+                                                    |
        text-wrapper                                                       |
        action-[a-z-]+                                                     |
        expand-icon
      )\z/x

      # Project-specific utility classes defined in glass_morph/utilities/*.css
      APP_UTILITY_PATTERN = /\A(
        [mp][tblrxyse]?-\d+px                                              |
        [mp][tblrxyse]?-0\d+                                               |
        p-\d+-\d+                                                          |
        gap-(?:xs|sm|md|lg|xl)                                             |
        flex-(?:between|center|start|end)(?:-[a-z]+-\d+)?                  |
        flex-col(?:-[a-z-]+)?                                              |
        flex-1                                                             |
        text-(?:xs|sm|md|lg|xl|2xl|3xl)                                    |
        text-(?:white|black|gray)-\d+                                      |
        text-primary-dark                                                  |
        min-w-0
      )\z/x

      # Exact-match allowlist for additional classes
      ALWAYS_ALLOWED = Set.new(%w[
        hidden block inline inline-block flex inline-flex grid
        relative absolute fixed sticky
        truncate fsmall lsmall input-hint
        section date-count date-info ftext-uppercase
        dialog streaming error cursor-help cursor-pointer
        z-1 min-width-0 border-t border-opacity-25
        btn-gradient text-gradient sources-list context-tabs
        dot-1 dot-2 dot-3 nav-chevron date-title
        grid-auto-fit-320 flex-fill-child-container
        configuration-card-clickable
      ]).freeze

      MESSAGE = "Avoid custom CSS classes. Use design tokens (gm-*), Bootstrap utilities, " \
                "or component parameters instead. Got: %<class_name>s"

      def check(tree)
        tree.each_node do |node|
          class_val = node.kwarg(:class)
          next if class_val.nil?
          next if class_val == :__dynamic__ || class_val == :__interpolated__
          next unless class_val.is_a?(String)

          tokens = class_val.split

          # Check each token against allowed patterns
          custom_tokens = tokens.reject do |token|
            token.match?(GM_TOKEN_PATTERN) ||
              token.match?(BOOTSTRAP_UTILITY_PATTERN) ||
              token.match?(APP_CSS_PATTERN) ||
              token.match?(APP_UTILITY_PATTERN) ||
              ALWAYS_ALLOWED.include?(token)
          end

          next if custom_tokens.empty?

          # Report the first custom token found
          violation(node, format(MESSAGE, class_name: custom_tokens.first))
        end
      end
    end
  end
end
