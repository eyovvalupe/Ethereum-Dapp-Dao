const SimpleToken = artifacts.require('SimpleToken')

contract('SimpleToken', (accounts) => {
  it(`Should put 100000 to the ${accounts[0]} `, async () => {
    const simpleTokenIns = await SimpleToken.deployed();
    const balance = (
      await simpleTokenIns.balanceOf.call(accounts[0])
    ).toNumber();

    assert.equal(
      balance,
      100000,
      `the balance of ${accounts[0]} } wasn not 100000`
    );
  });

  // change the account
  it('Transfer 100 to other account', async () => {
    const simpleTokenIns = await SimpleToken.deployed();

    const target = "0x96c94cedf3bed5ad0a31636fd6a5a64d2c2e2475";
    // transfer 1000 to other account
    await simpleTokenIns.transfer(target, 1000);

    // check the balance of target
    const balance = (await simpleTokenIns.balanceOf.call(target)).toNumber();
    assert.equal(balance, 1000, `the balance of ${target} wasn't 1000`);
  });
})
