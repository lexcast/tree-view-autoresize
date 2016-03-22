{CompositeDisposable} = require 'atom'

module.exports = TreeViewAutoresize =
  subscriptions: null

  activate: (state) ->
    @subscriptions = new CompositeDisposable

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->
