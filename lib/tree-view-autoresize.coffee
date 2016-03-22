{requirePackages} = require 'atom-utils'
{CompositeDisposable} = require 'atom'

module.exports = TreeViewAutoresize =
  subscriptions: null

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    requirePackages('tree-view').then ([treeView]) =>
      @treeView = treeView.treeView
      @treeView.on 'click', '.directory', (=> @resizeTreeView())
      @resizeTreeView()

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->

  resizeTreeView: ->
    currWidth = @treeView.list.outerWidth()
    if currWidth > @treeView.width()
      @treeView.animate {width: currWidth}, 300
    else
      @treeView.width 1
      @treeView.width @treeView.list.outerWidth()
      newWidth = @treeView.list.outerWidth()
      @treeView.width currWidth
      @treeView.animate {width: newWidth}, 300
