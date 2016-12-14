{requirePackages} = require 'atom-utils'
{CompositeDisposable} = require 'atom'
$ = require 'jquery'
scrollbarWidth = require('scrollbar-width')()

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
      default: 200
      description: 'Number of milliseconds to elapse during animations. Smaller means faster.'
    delayMilliseconds:
      type: 'integer'
      default: 200
      description: 'Number of milliseconds to wait before animations. Smaller means faster.'

  subscriptions: null
  max: 0
  min: 0
  pad: 0
  animationMs: 200
  delayMs: 200

  activate: (state) ->
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.config.observe 'tree-view-autoresize.maximumWidth',
      (max) =>
        @max = max

    @subscriptions.add atom.config.observe 'tree-view-autoresize.minimumWidth',
      (min) =>
        @min = min

    @subscriptions.add atom.config.observe 'tree-view-autoresize.padding', (pad) =>
        @pad = pad

    @subscriptions.add atom.config.observe 'tree-view-autoresize.animationMilliseconds',
      (animationMs) =>
        @animationMs = animationMs

    @subscriptions.add atom.config.observe 'tree-view-autoresize.delayMilliseconds',
      (delayMs) =>
        @delayMs = delayMs

    if atom.packages.isPackageLoaded 'nuclide-file-tree'
      $('body').on 'click.autoresize', '.nuclide-file-tree .directory', (e) =>
        @resizeNuclideFileTree()
      @subscriptions.add atom.project.onDidChangePaths (=> @resizeNuclideFileTree())
      @resizeNuclideFileTree()

    else
      requirePackages('tree-view').then ([treeView]) =>
        unless treeView.treeView?
          treeView.createView()
        @treeView = treeView.treeView
        @treeView.on 'click.autoresize', '.directory', (=> @resizeTreeView())
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
    @treeView?.unbind 'click.autoresize'
    $('body').unbind 'click.autoresize'

  serialize: ->

  resizeTreeView: ->
    setTimeout =>
      origListWidth = @treeView.list.outerWidth()
      origTreeWidth = @treeView.width()
      if origListWidth > origTreeWidth
        @treeView.animate {width: @getWidth(origListWidth + scrollbarWidth + @pad)}, @animationMs
      else
        @treeView.width 1
        @treeView.width @treeView.list.outerWidth()
        newTreeWidth = @getWidth(@treeView.list.outerWidth() + scrollbarWidth + @pad)
        @treeView.width origTreeWidth
        if origTreeWidth isnt newTreeWidth
          @treeView.animate {width: newTreeWidth}, @animationMs
    , @delayMs

  resizeNuclideFileTree: ->
    setTimeout =>
      fileTree = $('.tree-view-resizer')
      currWidth = fileTree.find('.nuclide-file-tree').outerWidth()
      if currWidth > fileTree.width()
        fileTree.animate {width: @getWidth(currWidth + 10)}, @animationMs
      else
        fileTree.width 1
        fileTree.width fileTree.find('.nuclide-file-tree').outerWidth()
        newWidth = fileTree.find('.nuclide-file-tree').outerWidth()
        fileTree.width currWidth
        fileTree.animate {width: @getWidth(newWidth + 10)}, @animationMs
    , @delayMs

  getWidth: (w) ->
    if @max is 0 or w < @max
      if @min is 0 or w > @min
        w
      else
        @min
    else
      @max
