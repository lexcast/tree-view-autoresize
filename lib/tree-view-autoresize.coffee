module.exports = TreeViewAutoresize =
  config:
    delayMilliseconds:
      type: 'integer'
      default: 100
      description: 'Number of milliseconds to wait before animations. Smaller means faster.'

  subscriptions: null
  delayMs: 100

  activate: () ->
    requestIdleCallback =>
      {requirePackages} = require 'atom-utils'
      {CompositeDisposable} = require 'atom'

      @subscriptions = new CompositeDisposable
      @subscriptions.add atom.config.observe 'tree-view-autoresize.delayMilliseconds',
        (delayMs) =>
          @delayMs = delayMs

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
    , @delayMs

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
      if node.classList.contains('left')
        return true
      node = node.parentNode
    false

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
