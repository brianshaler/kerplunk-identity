_ = require 'lodash'
React = require 'react'

{DOM} = React

module.exports = React.createFactory React.createClass
  render: ->
    avatarComponentPath = @props.globals.public.identity.avatarComponent
    AvatarComponent = @props.getComponent avatarComponentPath

    showNickName = false
    displayName = @props.identity.fullName
    if !displayName or displayName == ''
      displayName = @props.identity.nickName
    else if displayName != @props.identity.nickName
      showNickName = true

    DOM.div
      className: 'default-contact-card panel media'
      style:
        float: 'left'
        margin: '0 1em 1em 0'
        fontSize: '13px'
    ,
      DOM.div
        className: 'bd'
        style:
          float: 'left'
          padding: '0.4em'
      ,
        AvatarComponent _.extend {}, @props
      DOM.div
        style:
          float: 'left'
          padding: '0.4em 1em 0.4em 0'
      ,
        DOM.a
          onClick: @props.pushState
          href: "/admin/identity/view/#{@props.identity._id}"
        ,
          displayName
          if showNickName
            " (#{@props.identity.nickName})"
        @props.children
