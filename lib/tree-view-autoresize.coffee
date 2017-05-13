{requirePackages} = require 'atom-utils'
{CompositeDisposable} = require 'atom'
$ = require 'jquery'

module.exports = TreeViewAutoresize =
  config:
    delayMilliseconds:
      type: 'integer'
      default: 100
      description: 'Number of milliseconds to wait before animations. Smaller means faster.'

  subscriptions: null
  delayMs: 100

  activate: (state) ->
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.config.observe 'tree-view-autoresize.delayMilliseconds',
      (delayMs) =>
        @delayMs = delayMs

    requirePackages('tree-view').then ([treeView]) =>
      unless treeView.treeView?
        treeView.createView()
      @treePanel = $(treeView.treeView.element)

      @treePanel.on 'click.autoresize', '.directory', (=> @resizeTreeView())
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
      @resizeTreeView()

  deactivate: ->
    @subscriptions.dispose()
    @treePanel?.unbind 'click.autoresize'

  resizeTreeView: ->
    setTimeout =>
      if @treePanel.parents('.left').length
        atom.workspace.getLeftDock().handleResizeToFit()
      else
        atom.workspace.getRightDock().handleResizeToFit()
    , @delayMs
