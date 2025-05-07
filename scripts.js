require('dotenv').config();
const { ethers } = require('ethers');
const fs = require('fs');
const path = require('path');

const {
  ZKEVM_RPC_URL,
  POLYGON_POS_RPC_URL,
  PRIVATE_KEY,
  ZKEVM_PRODUCT_REGISTRY,
  ZKEVM_REVIEW_MANAGER,
  ZKEVM_REPUTATION_MANAGER,
  POS_PRODUCT_REGISTRY,
  POS_REVIEW_MANAGER,
  POS_REPUTATION_MANAGER
} = process.env;

// Load ABIs
const productRegistryABI = require('./ProductRegistry.json');
const reviewManagerABI = require('./ReviewManager.json');
const reputationManagerABI = require('./ReputationManager.json');

// How many full user flows to simulate
const NUM_FLOWS = 5;

// A helper function to send a transaction, wait for receipt, and record metrics
async function sendTransactionAndRecord(contractMethodCall) {
  const startTime = Date.now();
  const tx = await contractMethodCall;
  const receipt = await tx.wait();
  const endTime = Date.now();
  const latency = endTime - startTime;
  const gasUsed = receipt.gasUsed.toNumber();
  return { txHash: tx.hash, blockNumber: receipt.blockNumber, gasUsed, latencyMs: latency };
}

async function runFlowOnNetwork(networkName, productRegistryAddr, reviewManagerAddr, reputationManagerAddr, providerUrl) {
  console.log(`Running flows on ${networkName}...`);
  
  const provider = new ethers.providers.JsonRpcProvider(providerUrl);
  const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

  const productRegistry = new ethers.Contract(productRegistryAddr, productRegistryABI, wallet);
  const reviewManager = new ethers.Contract(reviewManagerAddr, reviewManagerABI, wallet);
  const reputationManager = new ethers.Contract(reputationManagerAddr, reputationManagerABI, wallet);

  let results = [];

  for (let i = 0; i < NUM_FLOWS; i++) {
    console.log(`Flow ${i+1}/${NUM_FLOWS} on ${networkName}`);
    
    // Generate random addresses for actors for each iteration
    const actor1Addr = ethers.Wallet.createRandom().address;
    const actor2Addr = ethers.Wallet.createRandom().address;
    
    // 1. Register Actors
    // Actor roles: "Farmer", "Distributor"
    let res1 = await sendTransactionAndRecord(productRegistry.registerActor(actor1Addr, "Actor1", "Farmer", ""));
    results.push({network: networkName, flow:i+1, step:"RegisterActor1", ...res1});

    let res2 = await sendTransactionAndRecord(productRegistry.registerActor(actor2Addr, "Actor2", "Distributor", ""));
    results.push({network: networkName, flow:i+1, step:"RegisterActor2", ...res2});

    // 2. Register a batch
    const batchId = ethers.utils.hexlify(ethers.utils.randomBytes(32));
    const grainType = 0; 
    const variety = "GoldenWheatV1";
    const harvestDate = Math.floor(Date.now()/1000);
    const initialQuality = 85;

    let res3 = await sendTransactionAndRecord(
      productRegistry.registerBatch(batchId, [actor1Addr, actor2Addr], grainType, variety, harvestDate, initialQuality)
    );
    results.push({network: networkName, flow:i+1, step:"RegisterBatch", ...res3});

    // 3. Intermediate Review
    // Example scores
    let Q=4, P=5,T=4,S=5,R=4;
    let res4 = await sendTransactionAndRecord(
      reviewManager.submitIntermediateReview(batchId, actor1Addr, Q,P,T,S,R)
    );
    results.push({network: networkName, flow:i+1, step:"IntermediateReview", ...res4});

    // 4. Final Review
    let Qf=3,Pf=5,Tf=3,Sf=4,Rf=5;
    let res5 = await sendTransactionAndRecord(
      reviewManager.submitFinalReview(batchId, Qf,Pf,Tf,Sf,Rf)
    );
    results.push({network: networkName, flow:i+1, step:"FinalReview", ...res5});
  }

  return results;
}

(async ()=>{
  try {
    // Run the full flows on both networks
    const zkResults = await runFlowOnNetwork("zkEVM", ZKEVM_PRODUCT_REGISTRY, ZKEVM_REVIEW_MANAGER, ZKEVM_REPUTATION_MANAGER, ZKEVM_RPC_URL);
    const posResults = await runFlowOnNetwork("PolygonPoS", POS_PRODUCT_REGISTRY, POS_REVIEW_MANAGER, POS_REPUTATION_MANAGER, POLYGON_POS_RPC_URL);

    const allResults = zkResults.concat(posResults);

    // Save results to CSV
    const csvHeader = "network,flow,step,txHash,blockNumber,gasUsed,latencyMs\n";
    const csvRows = allResults.map(r =>
      `${r.network},${r.flow},${r.step},${r.txHash},${r.blockNumber},${r.gasUsed},${r.latencyMs}`
    ).join("\n");

    const csvContent = csvHeader + csvRows;
    const outPath = path.join(__dirname, 'full_flow_results.csv');
    fs.writeFileSync(outPath, csvContent);

    console.log(`Results saved to ${outPath}`);
    console.log("Full flow test complete. Analyze the CSV for metrics.");
  } catch (err) {
    console.error("Error running flows:", err);
  }
})();
