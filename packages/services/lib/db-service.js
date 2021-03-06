const Service = require('@aws-ee/services-container/lib/service');

const Scanner = require('./db/scanner');
const Updater = require('./db/updater');
const Getter = require('./db/getter');
const Query = require('./db/query');
const Deleter = require('./db/deleter');
const BatchWriter = require('./db/batch-writer');
const unmarshal = require('./db/unmarshal');

class DbService extends Service {
  constructor() {
    super();
    this.dependency('aws');
  }

  async init() {
    await super.init();
    const aws = await this.service('aws');
    this.dynamoDb = new aws.sdk.DynamoDB({ apiVersion: '2012-08-10' });
    // Setting convertEmptyValues = true below, without this, if any item is asked to be updated with any attrib containing empty string
    // the dynamo update operation fails with
    // "ExpressionAttributeValues contains invalid value: One or more parameter values were invalid: An AttributeValue may not contain an empty string for key :desc" error
    // See https://github.com/aws/aws-sdk-js/issues/833 for details
    this.client = new aws.sdk.DynamoDB.DocumentClient({
      service: this.dynamoDb,
      convertEmptyValues: true,
    });

    this.helper = {
      unmarshal,
      scanner: () => new Scanner(this.log, this.client),
      updater: () => new Updater(this.log, this.client),
      getter: () => new Getter(this.log, this.client),
      query: () => new Query(this.log, this.client),
      deleter: () => new Deleter(this.log, this.client),
      batchWriter: () => new BatchWriter(this.log, this.client),
    };
  }
}

module.exports = DbService;
