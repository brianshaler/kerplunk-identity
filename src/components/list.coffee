_ = require 'lodash'
React = require 'react'
Bootstrap = require 'react-bootstrap'

Pagination = React.createFactory Bootstrap.Pagination

{DOM} = React

module.exports = React.createFactory React.createClass
  getInitialState: ->
    pages = {}
    currentPage = @props.currentPage ? 1
    console.log 'currentPage', currentPage, typeof currentPage
    pages[currentPage] = @props.identities

    currentPage: currentPage
    perPage: @props.perPage ? 20
    total: @props.total ? 0
    pages: pages
    sort: @props.sort
    dir: @props.dir

  resort: (obj) ->
    (e) =>
      e.preventDefault()
      newState = _.extend
        pages: {}
        currentPage: 1
      , obj
      @setState newState
      @showPage null, {eventKey: newState.currentPage}, _.extend {}, @state, newState

  showPage: (e, selectedEvent, newState = @state) ->
    currentPage = selectedEvent.eventKey
    console.log 'show page', currentPage
    pages = newState.pages
    if pages[currentPage]?
      @setState
        currentPage: currentPage
    else
      url = '/admin/contacts.json'
      opt =
        sort: newState.sort
        dir: newState.dir
        perPage: newState.perPage
        page: currentPage
      @props.request.get url, opt, (err, data) =>
        console.log 'received', data
        return unless @isMounted()
        return console.log err, data if err or !data?.state?.identities
        pages = @state.pages
        pages[currentPage] = data.state.identities

        @setState
          pages: pages
          total: data.state.total ? @state.total
      pages[currentPage] = 'loading'
      @setState
        pages: pages
        currentPage: currentPage

  goToIdentity: (identity) ->
    return unless identity?._id
    url = "/admin/identity/view/#{identity._id}"
    fakeClickEventLol =
      target:
        href: url
      currentTarget:
        href: url
      preventDefault: ->
    @props.pushState fakeClickEventLol

  render: ->
    identityConfig = @props.globals.public.identity
    cardComponentPath = identityConfig.contactCardComponent ? identityConfig.defaultContactCard
    ContactCard = @props.getComponent cardComponentPath
    Autocomplete = @props.getComponent 'kerplunk-identity-autocomplete:input'

    identities = @state.pages[@state.currentPage]
    loading = !identities? or identities == 'loading'

    DOM.section
      className: 'content'
    ,
      DOM.div null,
        DOM.h3 null, 'Search'
        Autocomplete _.extend {}, @props,
          onSelect: @goToIdentity
          identity: null
      DOM.div null,
        'Sort by: '
        if @state.sort == 'nickName'
          'nick name'
        else
          DOM.a
            onClick: @resort sort: 'nickName'
            href: "/admin/contacts?sortBy=nickName"
          , 'nick name'
        ' | '
        if @state.sort == 'firstName'
          'first name'
        else
          DOM.a
            onClick: @resort sort: 'firstName'
            href: "/admin/contacts?sortBy=firstName"
          , 'first name'
        ' | '
        if @state.sort == 'lastName'
          'last name'
        else
          DOM.a
            onClick: @resort sort: 'lastName'
            href: "/admin/contacts?sortBy=lastName"
          , 'last name'
        ' | '
        if @state.sort == 'lastInteraction'
          'last interaction'
        else
          DOM.a
            onClick: @resort sort: 'lastInteraction'
            href: "/admin/contacts?sortBy=lastInteraction"
          , 'last interaction'
      DOM.div null,
        'Order: '
        if @state.dir == 'asc'
          'ascending'
        else
          DOM.a
            onClick: @resort dir: 'asc'
            href: "/admin/contacts?dir=asc"
          , 'ascending'
        ' | '
        if @state.dir == 'desc'
          'descending'
        else
          DOM.a
            onClick: @resort dir: 'desc'
            href: "/admin/contacts?dir=desc"
          , 'descending'
      DOM.div null,
        Pagination
          prev: true
          next: true
          first: true
          last: true
          ellipsis: true
          items: Math.ceil @state.total / @state.perPage
          maxButtons: 5
          activePage: @state.currentPage
          onSelect: @showPage
      if loading
        'loading'
      else
        DOM.div
          className: 'clearfix'
        ,
          _.map identities, (identity) =>
            ContactCard _.extend {}, @props,
              key: "identity-#{identity._id}"
              identity: identity
      if !loading
        DOM.div
          className: 'clearfix'
        ,
          Pagination
            prev: true
            next: true
            first: true
            last: true
            ellipsis: true
            items: Math.ceil @state.total / @state.perPage
            maxButtons: 5
            activePage: @state.currentPage
            onSelect: @showPage
