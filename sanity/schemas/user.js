export default {
    name: 'user',
    type: 'document',
      title: 'Users',
    fields: [
      {
        name: 'name',
        type: 'string',
        title: 'Name'
      },
      {
        name: 'isVerified',
        type: 'boolean',
        title: 'User Verified?'
      },
      {
        name: 'signupDate',
        type: 'date',
        title: 'Date of Joining'
      },
      {
        name: 'walletAddress',
        type: 'string',
        title: 'Wallet Address'
      },
    ]
  }