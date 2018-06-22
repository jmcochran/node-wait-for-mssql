P = require 'bluebird'
Joi = require 'joi'

defaultConfig = ->
  host: 'localhost'
  port: 1433
  username: 'sa'
  password: ''
  database: 'master'
  connectTimeout: 2000
  totalTimeout: 15000
  query: null

defaults = defaultConfig()

schema = Joi.object().keys
  host: Joi.string().hostname().min(1).optional().default(defaults.host)
  port: Joi.number().integer().min(1).max(65536).optional().default(defaults.port)
  username: Joi.string().min(1).optional().default(defaults.username)
  password: Joi.string().optional().default(defaults.password)
  database: Joi.string().min(1).optional().default(defaults.database)
  connectTimeout: Joi.number().integer().min(0).optional().default(defaults.connectTimeout)
  totalTimeout: Joi.number().integer().min(0).optional().default(defaults.totalTimeout)
  query: Joi.string().min(1).optional().default(defaults.query)

verify = P.promisify Joi.validate
validate = (config) -> verify(config ? {}, schema)

module.exports =
  validate: validate
  default: defaultConfig
