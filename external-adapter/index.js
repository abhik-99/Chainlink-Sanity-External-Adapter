const { Requester, Validator } = require('@chainlink/external-adapter');
const sanityClient = require('@sanity/client');
const { utils } = require('ethers');

// Define custom parameters to be used by the adapter.
// Extra parameters can be stated in the extra object,
// with a Boolean value indicating whether or not they
// should be required.
const customParams = {
  walletAddr: ["wallet", "address", "walletAddress"],
  endpoint: false
}

const createRequest = (input, callback) => {
  // The Validator helps you validate the Chainlink request data
  const validator = new Validator(callback, input, customParams)
  const jobRunID = validator.validated.id;
  let walletAddr = validator.validated.data.walletAddr;
  walletAddr = utils.getAddress(walletAddr);

  const client = sanityClient({
    projectId: process.env.PROJECT_ID ,
    dataset: 'production',
    apiVersion: '2021-04-27', 
    token: process.env.API_TOKEN, 
    useCdn: false,
  });
  const query = `*[_type == "user" && walletAddress == $walletAddr] {isVerified, signupDate, walletAddress}`
  const params = {walletAddr};

  //id of the document to fetch
  client.fetch(query, params)
  .then((user) => {
    const {isVerified, signupDate, walletAddress} = user[0];
    const joined = Date.parse(signupDate+"T00:00:00")/1000;
    const qualified = Date.now()/1000 - joined > 20 * 24 * 60 * 60;
    const response = { data: { isVerified, qualified, walletAddress } };
    callback(200, Requester.success(jobRunID, response))

  })
  .catch(error => {
    callback(500, Requester.errored(jobRunID, error))
  })
}

// This is a wrapper to allow the function to work with
// GCP Functions
exports.gcpservice = (req, res) => {
  createRequest(req.body, (statusCode, data) => {
    res.status(statusCode).send(data)
  })
}

// This is a wrapper to allow the function to work with
// AWS Lambda
exports.handler = (event, context, callback) => {
  createRequest(event, (statusCode, data) => {
    callback(null, data)
  })
}

// This is a wrapper to allow the function to work with
// newer AWS Lambda implementations
exports.handlerv2 = (event, context, callback) => {
  createRequest(JSON.parse(event.body), (statusCode, data) => {
    callback(null, {
      statusCode: statusCode,
      body: JSON.stringify(data),
      isBase64Encoded: false
    })
  })
}

// This allows the function to be exported for testing
// or for running in express
module.exports.createRequest = createRequest
