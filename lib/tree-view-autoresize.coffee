{requirePackages} = require 'atom-utils'
{CompositeDisposable} = require 'atom'
$ = require 'jquery'

module.exports = TreeViewAutoresize =
  config:
    minimumWidth:
      type: 'integer'
      default: 0
      description: 'Minimum tree-view width. Put 0 if you don\'t want a min limit.'
    maximumWidth:
      type: 'integer'
      default: 0
      description: 'Maximum tree-view width. Put 0 if you don\'t want a max limit.'

  subscriptions: null
  max: 0
  min: 0

  activate: (state) ->
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.config.observe 'tree-view-autoresize.maximumWidth', (max) =>
      @max = max

    @subscriptions.add atom.config.observe 'tree-view-autoresize.minimumWidth', (min) =>
      @min = min

    if atom.packages.isPackageLoaded 'nuclide-file-tree'
      $('body').on 'click.autoresize', '.nuclide-file-tree .directory', (e) =>
        @resizeNuclideFileTree()
      @subscriptions.add atom.project.onDidChangePaths (=> @resizeNuclideFileTree())
      @resizeNuclideFileTree()

    else
      requirePackages('tree-view').then ([treeView]) =>
        @treeView = treeView.treeView
        @treeView.on 'click.autoresize', '.directory', (=> @resizeTreeView())
        @subscriptions.add atom.project.onDidChangePaths (=> @resizeTreeView())
        @subscriptions.add atom.commands.add 'atom-workspace', 'tree-view:reveal-active-file': => @resizeTreeView()
        @resizeTreeView()

  deactivate: ->
    @subscriptions.dispose()
    @treeView?.unbind 'click.autoresize'
    $('body').unbind 'click.autoresize'

  serialize: ->

  resizeTreeView: ->
    setTimeout =>
      currWidth = @treeView.list.outerWidth()
      if currWidth > @treeView.width()
        @treeView.animate {width: @getWidth(currWidth)}, 200
      else
        @treeView.width 1
        @treeView.width @treeView.list.outerWidth()
        newWidth = @treeView.list.outerWidth()
        @treeView.width currWidth
        @treeView.animate {width: @getWidth(newWidth)}, 200
    , 200

  resizeNuclideFileTree: ->
    setTimeout =>
      fileTree = $('.tree-view-resizer')
      currWidth = fileTree.find('.nuclide-file-tree').outerWidth()
      if currWidth > fileTree.width()
        fileTree.animate {width: @getWidth(currWidth + 10)}, 200
      else
        fileTree.width 1
        fileTree.width fileTree.find('.nuclide-file-tree').outerWidth()
        newWidth = fileTree.find('.nuclide-file-tree').outerWidth()
        fileTree.width currWidth
        fileTree.animate {width: @getWidth(newWidth + 10)}, 200
    , 200

  getWidth: (w) ->
    if @max is 0 or w < @max
      if @min is 0 or w > @min
        w
      else
        @min
    else
      @max
