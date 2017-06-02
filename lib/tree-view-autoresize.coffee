module.exports = TreeViewAutoresize =
  config:
    minimumWidth:
      type: 'integer'
      default: 0
      description:
        'Minimum tree-view width. Put 0 if you don\'t want a min limit.'
    maximumWidth:
      type: 'integer'
      default: 0
      description:
        'Maximum tree-view width. Put 0 if you don\'t want a max limit.'
    padding:
      type: 'integer'
      default: 0
      description: 'Add padding to the right side of the tree-view.'
    animationMilliseconds:
      type: 'integer'
      default: 150
      description: 'Number of milliseconds to elapse during animations. Smaller means faster.'
    delayMilliseconds:
      type: 'integer'
      default: 100
      description: 'Number of milliseconds to wait before animations. Smaller means faster.'

  subscriptions: null
  conf: []
  delayMs: 100

  activate: () ->
    requestIdleCallback =>
      {requirePackages} = require 'atom-utils'
      {CompositeDisposable} = require 'atom'

      @subscriptions = new CompositeDisposable
      @observe 'minimumWidth'
      @observe 'maximumWidth'
      @observe 'padding'
      @observe 'animationMilliseconds'
      @observe 'delayMilliseconds', false

      requirePackages('tree-view').then ([treeView]) =>
        unless treeView.treeView?
          treeView.createView()
        @treePanel = treeView.treeView.element
        @treePanel.style.width = null

        @initTreeViewEvents()
        @resizeTreeView()

  deactivate: ->
    @treePanel.removeEventListener 'click', @bindClick
    @subscriptions.dispose()

  resizeTreeView: ->
    setTimeout =>
      if @isInLeft()
        atom.workspace.getLeftDock().handleResizeToFit()
      else
        atom.workspace.getRightDock().handleResizeToFit()
    , @conf['delayMilliseconds']

  onClickDirectory: (e) ->
    node = e.target
    while node != null and node != @treePanel
      if node.classList.contains('directory')
        @resizeTreeView()
        return
      node = node.parentNode

  isInLeft: ->
    node = @treePanel.parentNode
    while node != null
      if node.classList?.contains('left')
        return true
      node = node.parentNode
    false

  setStyles: ->
    if not @style
      @style = document.createElement 'style'
      @style.type = 'text/css'

    css = @generateCss()
    @style.innerHTML = css
    document.body.appendChild @style

  observe: (key, updateStyles = true) ->
    @subscriptions.add atom.config.observe "tree-view-autoresize.#{key}",
      (value) =>
        @conf[key] = value
        @setStyles() if updateStyles

  initTreeViewEvents: ->
    @bindClick = @onClickDirectory.bind(this)
    @treePanel.addEventListener 'click', @bindClick
    @subscriptions.add atom.project.onDidChangePaths (=> @resizeTreeView())
    @subscriptions.add atom.commands.add 'atom-workspace',
      'tree-view:reveal-active-file': => @resizeTreeView()
      'tree-view:toggle': => @resizeTreeView()
      'tree-view:show': => @resizeTreeView()
    @subscriptions.add atom.commands.add '.tree-view',
      'tree-view:open-selected-entry': => @resizeTreeView()
      'tree-view:expand-item': => @resizeTreeView()
      'tree-view:recursive-expand-directory': => @resizeTreeView()
      'tree-view:collapse-directory': => @resizeTreeView()
      'tree-view:recursive-collapse-directory': => @resizeTreeView()
      'tree-view:move': => @resizeTreeView()
      'tree-view:cut': => @resizeTreeView()
      'tree-view:paste': => @resizeTreeView()
      'tree-view:toggle-vcs-ignored-files': => @resizeTreeView()
      'tree-view:toggle-ignored-names': => @resizeTreeView()
      'tree-view:remove-project-folder': => @resizeTreeView()

  generateCss: ->
    css = "
      atom-dock.left .atom-dock-open .atom-dock-content-wrapper:not(:active),
      atom-dock.left .atom-dock-open .atom-dock-mask:not(:active),
      atom-dock.right .atom-dock-open .atom-dock-content-wrapper:not(:active),
      atom-dock.right .atom-dock-open .atom-dock-mask:not(:active) {
        transition: width #{@conf['animationMilliseconds']}ms linear;
      }
    "

    if @conf['minimumWidth'] > 0
      css += "
        atom-dock.left .atom-dock-open .atom-dock-mask,
        atom-dock.right .atom-dock-open .atom-dock-mask {
          min-width: #{@conf['minimumWidth']}px;
        }
        atom-dock.left .atom-dock-open .atom-dock-mask .atom-dock-content-wrapper,
        atom-dock.right .atom-dock-open .atom-dock-mask .atom-dock-content-wrapper {
          min-width: #{@conf['minimumWidth']}px;
        }
      "

    if @conf['maximumWidth'] > 0
      css += "
        atom-dock.left .atom-dock-open .atom-dock-mask,
        atom-dock.right .atom-dock-open .atom-dock-mask {
          max-width: #{@conf['maximumWidth']}px;
        }
        atom-dock.left .atom-dock-open .atom-dock-mask .atom-dock-content-wrapper,
        atom-dock.right .atom-dock-open .atom-dock-mask .atom-dock-content-wrapper {
          max-width: #{@conf['maximumWidth']}px;
        }
      "

    if @conf['padding']
      css += "
        atom-dock.left .tree-view .full-menu,
        atom-dock.right .tree-view .full-menu {
          padding-right: #{@conf['padding']}px;
        }
      "

    css
