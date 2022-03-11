const main = async () => {
  const [owner, randomPerson] = await hre.ethers.getSigners();
  const contractFactory = await hre.ethers.getContractFactory('Domains');

  const contract = await contractFactory.deploy();
  await contract.deployed();

  console.log("Contract deployed to:", contract.address);
  console.log('owner of the contract is: ', owner.address);

  // my new campaign name
  const today = Math.floor(new Date().getTime() / 1000);
  const later = Math.floor(new Date("mar 20").getTime() / 1000);

  const mycampaign = {
    name: "my new campaign",
    startDate: today,
    endDate: later,
    nftT1: "",
    nftT2: "",
    nftT3: "",
  }

  // register a new domain
  // and provide registration payment
  let txn = await contract.register(
    ...Object.values(mycampaign),
    { value: hre.ethers.utils.parseEther('0.1') }
  );
  await txn.wait();

  // // retrieve the address of the domain
  // const domainOwner = await contract.resolveDomain(FQDN);
  // console.log(`The domain ${FQDN} belongs to the user with address: ${domainOwner}`);

  // // set record for domain
  // await contract.setRecord(FQDN, 'company name', 'companyname.com', 'Some address. NY, USA');

  // // get record of domain
  // const domainRecord = await contract.getRecord(FQDN);
  // console.log(`Business of at the domain ${mydomain} is ${domainRecord.name}`);

  // // get user's balance
  // const balance = await hre.ethers.provider.getBalance(contract.address);
  // console.log('Balance is :', hre.ethers.utils.formatEther(balance));

  // withdraw balance
  /* txn = await contract.connect(owner).withdraw();
  await txn.wait();

  // Fetch balance of contract & owner
  const contractBalance = await hre.ethers.provider.getBalance(contract.address);
  ownerBalance = await hre.ethers.provider.getBalance(owner.address);

  console.log("Contract balance after withdrawal:", hre.ethers.utils.formatEther(contractBalance));
  console.log("Balance of owner after withdrawal:", hre.ethers.utils.formatEther(ownerBalance));

  // return list of registered domains
  txn = await contract.getDomainList();

  console.log('list of domains:')
  console.log(txn) */
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