// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades, tenderly } = require("hardhat");
const { chainIdToAddresses } = require("../scripts/networkVariables");

async function main() {
  let owner;
  let treasury;
  let accounts = await ethers.getSigners();
  [owner, treasury] = accounts;

  const forkChainId: any = process.env.CHAIN_ID;
  const chainId: any = forkChainId ? forkChainId : 17000;
  const addresses = chainIdToAddresses[chainId];

  console.log("--------------- Contract Deployment Started ---------------");

  console.log("Deploying mock price feeds...");
  const MockPriceAggregator = await ethers.getContractFactory("MockPriceAggregator");

  // Deploy mock price feeds without constructor arguments
  const ethUsdPriceFeed = await MockPriceAggregator.deploy();
  await ethUsdPriceFeed.deployed();
  await ethUsdPriceFeed.setPrice(ethers.utils.parseEther("2000")); // $2000

  const usdcUsdPriceFeed = await MockPriceAggregator.deploy();
  await usdcUsdPriceFeed.deployed();
  await usdcUsdPriceFeed.setPrice(ethers.utils.parseEther("1")); // $1

  const daiUsdPriceFeed = await MockPriceAggregator.deploy();
  await daiUsdPriceFeed.deployed();
  await daiUsdPriceFeed.setPrice(ethers.utils.parseEther("1")); // $1

  console.log("Mock price feeds deployed:");
  console.log("ETH/USD:", ethUsdPriceFeed.address);
  console.log("USDC/USD:", usdcUsdPriceFeed.address);
  console.log("DAI/USD:", daiUsdPriceFeed.address);

  const PriceOracle = await ethers.getContractFactory("PriceOracle");
  const priceOracle = await PriceOracle.deploy(addresses.WETH_Address);
  await priceOracle.deployed();

  console.log("priceOracle address:", priceOracle.address);

  // Set up price feeds with USD (Denominations.USD) as quote
  const USD = "0x0000000000000000000000000000000000000348"; // This is Chainlink's USD denomination address

  await priceOracle.setFeeds(
    [addresses.WETH_Address, addresses.USDC_Address, addresses.DAI_Address],
    [USD, USD, USD], // All prices are quoted in USD
    [ethUsdPriceFeed.address, usdcUsdPriceFeed.address, daiUsdPriceFeed.address]
  );

  // await tenderly.verify({
  //   name: "PriceOracle",
  //   address: priceOracle.address,
  // });

  const EnsoHandler = await ethers.getContractFactory("EnsoHandler");
  const ensoHandler = await EnsoHandler.deploy();

  console.log("ensoHandler address:", ensoHandler.address);
  console.log("owner address:", owner.address);

  // await tenderly.verify({
  //   name: "EnsoHandler",
  //   address: ensoHandler.address,
  // });

  const ProtocolConfig = await ethers.getContractFactory("ProtocolConfig");
  const protocolConfig = await upgrades.deployProxy(ProtocolConfig, [
    owner.address,
    priceOracle.address,
  ],
    {
      kind: "uups",
      unsafeAllow: ["constructor"]
    },
  );

  console.log("protocolConfig address:", protocolConfig.address);

  // await tenderly.verify({
  //   name: "ProtocolConfig",
  //   address: protocolConfig.address,
  // });

  const contractOwner = await protocolConfig.owner();
  console.log("contractOwner address:", contractOwner);

  console.log("Token addresses to enable:", [
    addresses.WETH_Address,
    addresses.USDC_Address,
    addresses.DAI_Address
  ]);

  await protocolConfig.enableTokens([
    addresses.WETH_Address,
    addresses.USDC_Address,
    addresses.DAI_Address,
  ]);

  console.log("protocolConfig enabled tokens");

  await protocolConfig.updateProtocolFee(0);
  await protocolConfig.updateProtocolStreamingFee(0);

  console.log("protocolConfig updated protocol fee and streaming fee");

  await protocolConfig.setCoolDownPeriod("60");

  await protocolConfig.enableSolverHandler(ensoHandler.address);

  console.log("protocolConfig enabled solver handler");

  const Rebalancing = await ethers.getContractFactory("Rebalancing");
  const rebalancingDefault = await Rebalancing.deploy();

  console.log("rebalancingDefult address:", rebalancingDefault.address);

  // await tenderly.verify({
  //   name: "Rebalancing",
  //   address: rebalancingDefault.address,
  // });

  const AssetManagementConfig = await ethers.getContractFactory(
    "AssetManagementConfig",
  );
  const assetManagementConfig = await AssetManagementConfig.deploy();

  console.log("assetManagerConfig address:", assetManagementConfig.address);

  // await tenderly.verify({
  //   name: "AssetManagementConfig",
  //   address: assetManagementConfig.address,
  // });

  const Portfolio = await ethers.getContractFactory("Portfolio");
  const portfolioContract = await Portfolio.deploy();

  console.log("portfolioContract address:", portfolioContract.address);

  // await tenderly.verify({
  //   name: "Portfolio",
  //   address: portfolioContract.address,
  // });

  const FeeModule = await ethers.getContractFactory("FeeModule");
  const feeModule = await FeeModule.deploy();
  await feeModule.deployed();

  console.log("feeModule address:", feeModule.address);

  // await tenderly.verify({
  //   name: "FeeModule",
  //   address: feeModule.address,
  // });

  const VelvetSafeModule = await ethers.getContractFactory("VelvetSafeModule");
  const velvetSafeModule = await VelvetSafeModule.deploy();
  await velvetSafeModule.deployed();
  console.log("velvetSafeModule address:", velvetSafeModule.address);

  // await tenderly.verify({
  //   name: "VelvetSafeModule",
  //   address: velvetSafeModule.address,
  // });

  const TokenExclusionManager = await ethers.getContractFactory(
    "TokenExclusionManager",
  );
  const tokenExclusionManager = await TokenExclusionManager.deploy();
  await tokenExclusionManager.deployed();

  console.log("tokenExclusionManager address:", tokenExclusionManager.address);

  // await tenderly.verify({
  //   name: "TokenExclusionManager",
  //   address: tokenExclusionManager.address,
  // });

  const TokenRemovalVault = await ethers.getContractFactory(
    "TokenRemovalVault",
  );
  const tokenRemovalVault = await TokenRemovalVault.deploy();
  await tokenRemovalVault.deployed();

  console.log("tokenRemovalVault address:", tokenRemovalVault.address);

  // await tenderly.verify({
  //   name: "TokenRemovalVault",
  //   address: tokenRemovalVault.address,
  // });

  const DepositBatch = await ethers.getContractFactory("DepositBatch");
  const depositBatch = await DepositBatch.deploy();
  await depositBatch.deployed();
  console.log("depositBatch address:", depositBatch.address);

  // await tenderly.verify({
  //   name: "DepositBatch",
  //   address: depositBatch.address,
  // });

  const DepositManager = await ethers.getContractFactory("DepositManager");
  const depositManager = await DepositManager.deploy(depositBatch.address);
  await depositManager.deployed();
  console.log("depositManager address:", depositManager.address);

  // await tenderly.verify({
  //   name: "DepositManager",
  //   address: depositManager.address,
  // });

  const WithdrawBatch = await ethers.getContractFactory("WithdrawBatch");
  const withdrawBatch = await WithdrawBatch.deploy();
  await withdrawBatch.deployed();

  console.log("withdrawBatch address:", withdrawBatch.address);

  // await tenderly.verify({
  //   name: "WithdrawBatch",
  //   address: withdrawBatch.address,
  // });

  const PortfolioCalculations = await ethers.getContractFactory(
    "PortfolioCalculations",
  );
  const portfolioCalculations = await PortfolioCalculations.deploy();
  await portfolioCalculations.deployed();

  console.log("portfolioCalculations address:", portfolioCalculations.address);

  // await tenderly.verify({
  //   name: "PortfolioCalculations",
  //   address: portfolioCalculations.address,
  // });

  console.log(
    "------------------------------ Deployment Ended ------------------------------",
  );

  const PortfolioFactory = await ethers.getContractFactory("PortfolioFactory");

  const portfolioFactoryInstance = await upgrades.deployProxy(
    PortfolioFactory,
    [
      {
        _basePortfolioAddress: portfolioContract.address,
        _baseTokenExclusionManagerAddress: tokenExclusionManager.address,
        _baseRebalancingAddres: rebalancingDefault.address,
        _baseAssetManagementConfigAddress: assetManagementConfig.address,
        _feeModuleImplementationAddress: feeModule.address,
        _baseTokenRemovalVaultImplementation: tokenRemovalVault.address,
        _baseVelvetGnosisSafeModuleAddress: velvetSafeModule.address,
        _gnosisSingleton: addresses.gnosisSingleton,
        _gnosisFallbackLibrary: addresses.gnosisFallbackLibrary,
        _gnosisMultisendLibrary: addresses.gnosisMultisendLibrary,
        _gnosisSafeProxyFactory: addresses.gnosisSafeProxyFactory,
        _protocolConfig: protocolConfig.address,
      },
    ],
    {
      kind: "uups",
      unsafeAllow: ["constructor"]
    },
  );

  const portfolioFactory = PortfolioFactory.attach(
    portfolioFactoryInstance.address,
  );

  console.log("portfolioFactory address:", portfolioFactory.address);

  const WithdrawManager = await ethers.getContractFactory("WithdrawManager");
  const withdrawManager = await WithdrawManager.deploy();
  await withdrawManager.deployed();

  console.log("withdrawManager address:", withdrawManager.address);

  // await tenderly.verify({
  //   name: "WithdrawManager",
  //   address: withdrawManager.address,
  // });

  await withdrawManager.initialize(
    withdrawBatch.address,
    portfolioFactory.address,
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
