Reqs = require './reqs'
Coder = require './lib/Coder'
Protocol = require './lib/Protocol'

modules =
    coders: []
    protocols: [
        'JRPCProtocol'
    ]

Reqs.require = (path) -> Reqs.addModule require path

for own path, arr of modules
    for name in arr
        Reqs.require "./#{path}/#{name}"

module.exports = Reqs