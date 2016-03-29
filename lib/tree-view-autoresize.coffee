{requirePackages} = require 'atom-utils'
{CompositeDisposable} = require 'atom'
$ = require 'jquery'

module.exports = TreeViewAutoresize =
  subscriptions: null

  activate: (state) ->
    @subscriptions = new CompositeDisposable

    if atom.packages.isPackageLoaded 'nuclide-file-tree'
      $('body').on 'click', '.nuclide-file-tree .directory', (e) =>
        @resizeNuclideFileTree()
      atom.project.onDidChangePaths (=> @resizeNuclideFileTree())
      @resizeNuclideFileTree()

    else
      requirePackages('tree-view').then ([treeView]) =>
        @treeView = treeView.treeView
        @treeView.on 'click', '.directory', (=> @resizeTreeView())
        atom.project.onDidChangePaths (=> @resizeTreeView())
        @resizeTreeView()

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->

  resizeTreeView: ->
    currWidth = @treeView.list.outerWidth()
    if currWidth > @treeView.width()
      @treeView.animate {width: currWidth}, 200
    else
      @treeView.width 1
      @treeView.width @treeView.list.outerWidth()
      newWidth = @treeView.list.outerWidth()
      @treeView.width currWidth
      @treeView.animate {width: newWidth}, 200

  resizeNuclideFileTree: ->
    setTimeout ->
      fileTree = $('.tree-view-resizer')
      currWidth = fileTree.find('.nuclide-file-tree').outerWidth()
      if currWidth > fileTree.width()
        fileTree.animate {width: currWidth + 10}, 200
      else
        fileTree.width 1
        fileTree.width fileTree.find('.nuclide-file-tree').outerWidth()
        newWidth = fileTree.find('.nuclide-file-tree').outerWidth()
        fileTree.width currWidth
        fileTree.animate {width: newWidth + 10}, 200
    , 200
