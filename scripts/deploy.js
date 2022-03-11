const main = async () => {
  const [owner, randomPerson] = await hre.ethers.getSigners();
  const contractFactory = await hre.ethers.getContractFactory('CampaignNFT');

  const contract = await contractFactory.deploy(01);
  await contract.deployed();

  console.log("Contract deployed to :", contract.address);
  console.log("Contract owner :", contract.address);

  // my new campaign name
  const later = Math.floor(new Date("mar 20, 2022").getTime() / 1000);
  const later2 = Math.floor(new Date("mar 30, 2022").getTime() / 1000);

  const mycampaigns = [
    {
      name: "my new campaign",
      endDate: later
    },
    {
      name: "Other One",
      endDate: later2
    }
  ]

  let contractBalance = await hre.ethers.provider.getBalance(contract.address);
  let ownerBalance = await hre.ethers.provider.getBalance(owner.address);

  console.log("Contract balance before :", hre.ethers.utils.formatEther(contractBalance));
  console.log("Balance of owner before:", hre.ethers.utils.formatEther(ownerBalance));

  // anti TOA counter
  let txCounter = await contract.getTxCounter();

  // register a new domain
  // and provide registration payment
  let txn = await Promise.all(
    mycampaigns.map(async campaign => {
      await contract.register(
        ...Object.values(campaign),
        txCounter,
        { value: hre.ethers.utils.parseEther('0.45') }
      );
    })
  );

  contractBalance = await hre.ethers.provider.getBalance(contract.address);
  ownerBalance = await hre.ethers.provider.getBalance(owner.address);

  console.log("Contract balance after:", hre.ethers.utils.formatEther(contractBalance));
  console.log("Balance of owner after:", hre.ethers.utils.formatEther(ownerBalance));

  // return list of campaigns
  const campaignlist = await contract.getCampaigns();
  console.log(campaignlist.length)
  console.log(JSON.stringify(campaignlist, null, 3))

  // withdraw balance
  txn = await contract.connect(owner).withdraw();
  await txn.wait();

  console.log("Contract balance after withdraw:", hre.ethers.utils.formatEther(contractBalance));
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();