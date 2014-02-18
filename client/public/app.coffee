$ ->

    # Prepare spin
    $.fn.spin = (opts, color, content) ->
        presets =
            tiny:
                lines: 8
                length: 2
                width: 2
                radius: 3

            small:
                lines: 8
                length: 1
                width: 2
                radius: 5

            large:
                lines: 10
                length: 8
                width: 4
                radius: 8

        if Spinner
            @each ->
                $this = $ this
                $this.html "&nbsp;"
                spinner = $this.data "spinner"
                if spinner?
                    spinner.stop()
                    $this.data "spinner", null
                    $this.html content

                else if opts isnt false
                    if typeof opts is "string"
                        if opts of presets
                            opts = presets[opts]
                        else
                            opts = {}
                        opts.color = color if color
                    spinner = new Spinner(
                        $.extend(color: $this.css("color"), opts))
                    spinner.spin this
                    $this.data "spinner", spinner

        else
            console.log "Spinner class not available."
            null


    button = $('#generate-btn')
    button.startLoading = ->
        button.text '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
        button.spin 'tiny'
    button.endLoading = ->
        button.spin()
        button.html 'Reset Credentials'

    button.click ->
        button.startLoading()
        client.post 'token', {},
            success: (data) ->
                $('#password-span').html data.account.password
                button.endLoading()
            error: (err) ->
                button.endLoading()

    # menu management
    $('.tab.caldav').click ->
        $('.tab.caldav.selected').removeClass 'selected'
        $('.caldavconf:visible').hide()
        $(this).addClass 'selected'
        device = $(this).data 'device'
        $(".caldavconf[data-device='#{device}']").show()

    $('.tab.carddav').click ->
        $('.tab.carddav.selected').removeClass 'selected'
        $('.carddavconf:visible').hide()
        $(this).addClass 'selected'
        device = $(this).data 'device'
        $(".carddavconf[data-device='#{device}']").show()
