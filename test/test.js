const { expect } = require("chai");

var DiscoverBlockchainToken;
var agora;
var polis;
var newPolis
var owner;
var owner2;
var caino;
var agoraFounder1;
var agoraFounder2;
var agoraFutureAssociate;
var futureAssociate;
var dbtFutureAssociate;
var timestamp;
var endingVote;
var expiration;

function waitFor(seconds){
  return new Promise((resolve)=>{
    setTimeout(()=>{
      resolve()
    },seconds)
  })
}

function getTimestamp(){
  return Math.floor(Date.now()/1000)
}

describe("DISCOVER-BLOCKCHAIN-DAO-V3", function () {
  it("Deployment should assign owner to founders and associate", async function () {
    [owner,owner2,caino] = await ethers.getSigners();
    futureAssociate=caino;
    // console.log(owner.address)
    const Token = await ethers.getContractFactory("DiscoverBlockchainToken");
    DiscoverBlockchainToken = await Token.deploy([owner.address,owner2.address]);
    dbtFutureAssociate = DiscoverBlockchainToken.connect(futureAssociate);

    expect(await DiscoverBlockchainToken.associates(owner.address));
    expect(await DiscoverBlockchainToken.founders(owner2.address));
  });
  it("We should be able to claim tokens",async()=>{
    expect(await DiscoverBlockchainToken.claimToken());
  })
  it("We should be able to have a positive balance of the first two tokens, null of the third",async()=>{
    expect(await DiscoverBlockchainToken.balanceOf(owner.address,0)>0);
    expect(await DiscoverBlockchainToken.balanceOf(owner2.address,1)>0);
    expect(await DiscoverBlockchainToken.balanceOf(owner.address,1)==0);
  })
  it("Deployment of POLIS should be good",async()=>{
    // const AGORA = await ethers.getContractFactory("AgoraDiscoverBlockchain");
    //we skip deployment of agora, we consider polis contract both as AGORA and POLIS
    const POLIS = await ethers.getContractFactory("DiscoverBlockchainPolis");
    polis = await POLIS.deploy(DiscoverBlockchainToken.address)//
  })
  it("Deployment of AGORA should be good",async()=>{
    const AGORA = await ethers.getContractFactory("DiscoverBlockchainAgora");
    agora = await AGORA.deploy(DiscoverBlockchainToken.address,polis.address)
    //now we load the abi of polis on agora
    //if you need to call agora functions, just reassign agora = await ethers.getContractAt("DiscoverBlockchainAgora",agora.address);
    agora = await ethers.getContractAt("DiscoverBlockchainPolis",agora.address);
  })
  it("We should be able to set polis and agora addresses (leviathanic)",async()=>{
      expect(await DiscoverBlockchainToken.setInitialAgoraAddress(agora.address));
      expect(await DiscoverBlockchainToken.setInitialPolisAddress(polis.address));
  })
  it("We should get access to DBT address via AGORA",async()=>{
    expect((await agora.addressDBT())==DiscoverBlockchainToken.address)
  })
  it("We should be able to free the cages",async()=>{
      expect(await DiscoverBlockchainToken.openTheCages())
  })
  var id
  var prop
  it("We should be able to create separate instances of AGORA contract",async()=>{
    agoraFounder1=agora.connect(owner);
    agoraFounder2=agora.connect(owner2);
    agoraFutureAssociate=agora.connect(futureAssociate);
    expect(true)
  })
  it("We should be able to create a base proposal (owner1)",async()=>{
      timestamp = Math.floor(Date.now()/1000);
      endingVote = timestamp+15;
      expiration = timestamp+500000000000;
      expect(await agoraFounder1.createBaseProposal(["Questa proposta è un meme!"],endingVote,expiration))
  })
  it("We should be able to get access to the first proposal",async()=>{
    id = await agora.totalProposals();
    prop = await agora.getProposal(id);
    // console.log(prop)
    expect(!prop.status[0])
  })
  it("We should be able to create a full governance proposal (owner2)",async()=>{
    timestamp = Math.floor(Date.now()/1000);
    endingVote = timestamp+15;
    expiration = timestamp+500000000000;
    expect(await agoraFounder2.createFullProposal(["Prima proposta governance piena!"],endingVote,expiration,true,1,[futureAssociate.address],[],[]))
  })
  it("We should be able to get access to the second proposal",async()=>{
    id = await agora.totalProposals();
    prop = await agora.getProposal(id);
    // console.log(prop)
    expect(!prop.status[0])
  })
  it("We should be able to vote the governance proposal (owner1 and owner2)",async()=>{
    expect(await agoraFounder1.voteGovernanceProposal(id))
    expect(await agoraFounder2.voteGovernanceProposal(id))
  })
  it("We should not be able to vote the governance proposal again",async()=>{
    try{
      await agora.voteGovernanceProposal(id)
    }catch(e){
      expect(true)
    }
  })
  it("We should have gained some reputation",async()=>{
    expect((await agora.reputation[owner.address])>0)
  })
  it("We should incurr in error if we try to add members while proposal is pending",async()=>{
    //This because we're not the leviathan
    try{
        await DiscoverBlockchainToken.addAssociates(id)
    }catch(e){
        // console.log(e)
        expect(true)
    }
  })

  it("We wait the end of the voting time-window",async()=>{
    var smallT = Math.floor(Date.now()/1000)
    expect(await waitFor(endingVote>smallT?(endingVote-smallT)*1000:0))
    // expect(await waitFor(7000))
  })

  it("Now we should be able to approve the proposal (owner2)",async()=>{
    expect(await agoraFounder2.closeGovernanceProposal(id))
    var proposal = await agora.proposals(id);
    console.log(await agora.getProposalStatus(id))
    // console.log(proposal);
  })

  it("Associates, assemble!",async()=>{
    expect(await DiscoverBlockchainToken.associates(futureAssociate.address))
  })

  it("We expect new associate to claim tokens",async()=>{
    expect(await dbtFutureAssociate.claimToken())
  })

  it("We expect balance of the new associate to be positive",async()=>{
    expect((await dbtFutureAssociate.balanceOf(futureAssociate.address,1))>0)
  })

  it("We expect the new associate to create a proposal for being ostracized (lmao wtf)",async()=>{
    timestamp = Math.floor(Date.now()/1000);
    endingVote = timestamp+15;
    expiration = timestamp+500000000000;
    expect(await agoraFutureAssociate.createFullProposal(["Sarò ostracizzato nuu"],endingVote,expiration,true,3,[futureAssociate.address],[],[]))
  })
  it("We should be able to get access to the second proposal",async()=>{
    id = await agora.totalProposals();
    prop = await agora.getProposal(id);
    // console.log(prop)
    expect(!prop.status[0])
  })

  it("We should be able to vote the governance proposal (owner1 and new associate)",async()=>{
    expect(await agoraFounder1.voteGovernanceProposal(id))
    expect(await agoraFutureAssociate.voteGovernanceProposal(id))
  })

  it("We expect the new associate to have gained some reputation",async()=>{
    expect((await agora.reputation[futureAssociate.address])>0)
  })

  it("We expect that data is stored in AGORA and not in POLIS",async()=>{
    expect((await polis.totalReputation())==0)
    expect((await polis.totalReputation())>0)
  })

  it("We wait the end of the voting time-window",async()=>{
    var smallT = Math.floor(Date.now()/1000)
    expect(await waitFor(endingVote>smallT?(endingVote-smallT)*1000:0))
    // expect(await waitFor(7000))
  })

  it("Now we should be able to approve the proposal (owner2)",async()=>{
    expect(await agoraFounder2.closeGovernanceProposal(id))
    var proposal = await agora.proposals(id);
    console.log(await agora.getProposalStatus(id))
    // console.log(proposal);
  })

  it("Ex associate shall be gone",async()=>{
    var isAssociate = await DiscoverBlockchainToken.associates(futureAssociate.address);
    var balance = await DiscoverBlockchainToken.balanceOf(futureAssociate.address,1);
    var rep = await agora.reputation(futureAssociate.address);
    var hasClaimed = await DiscoverBlockchainToken.tokenClaimedList(futureAssociate.address,1);
    expect(!isAssociate)
    expect(balance==0);
    expect(rep==0);
    expect(!hasClaimed);
  })
  
  it("Ex associate shouldn't be able to claim token",async()=>{
    try{
      await dbtFutureAssociate.claimToken()
    }catch(e){
      expect(true)
    }
  })

  it("We should be able to deploy newPolis.sol",async()=>{
    const NEWPOLIS = await ethers.getContractFactory("DiscoverBlockchainNewPolis");
    newPolis = await NEWPOLIS.deploy(DiscoverBlockchainToken.address)
  })

  it("We shall be able to create the newPolis proposal",async()=>{
    timestamp = Math.floor(Date.now()/1000);
    endingVote = timestamp+30;
    expiration = timestamp+500000000000;
    expect(await agoraFounder2.createFullProposal(["A new dawn is coming!"],endingVote,expiration,true,0,[newPolis.address],[],[]))
  })

  it("We should be able to get access to the second proposal",async()=>{
    id = await agora.totalProposals();
    prop = await agora.getProposal(id);
    // console.log(prop)
    expect(!prop.status[0])
  })
  it("We should be able to vote the governance proposal (owner1 and owner2) (new polis)",async()=>{
    expect(await agoraFounder1.voteGovernanceProposal(id))
    expect(await agoraFounder2.voteGovernanceProposal(id))
  })
  it("We should not be able to vote the governance proposal again",async()=>{
    try{
      await agora.voteGovernanceProposal(id)
    }catch(e){
      expect(true)
    }
  })

  it("We wait the end of the voting time-window",async()=>{
    var smallT = Math.floor(Date.now()/1000)
    expect(await waitFor(endingVote>smallT?(endingVote-smallT)*1000:0))
    // expect(await waitFor(7000))
  })

  it("Now we should be able to approve the proposal (owner2)",async()=>{
    expect(await agoraFounder2.closeGovernanceProposal(id))
    var proposal = await agora.proposals(id);
    console.log(await agora.getProposalStatus(id))
    // console.log(proposal);
  })

  it("We shall be able to update agora contract with new ABI",async()=>{
    agora = await ethers.getContractAt("DiscoverBlockchainNewPolis",agora.address);
  })

  it("We shall be able to call the new method...",async()=>{
    expect(await agora.storeTest())
  })

  it("...the new polis contract should be updated...",async()=>{
    expect(await DiscoverBlockchainToken.getCurrentPolisAddress()==newPolis.address);
    agora = await ethers.getContractAt("DiscoverBlockchainAgora",agora.address);
    expect(await agora._getPolisAddress()==newPolis.address)
  })

  it("... to access the new variable...",async()=>{
    agora = await ethers.getContractAt("DiscoverBlockchainNewPolis",agora.address);
    expect(await agora.test())
  })

  it("... and to the method that returns the variable",async()=>{
    expect((await agora.getTest())==true)
  })

  it("Older state variables should have remained unaltered",async()=>{
    id = await agora.totalProposals();
    expect(id>0);
    prop = await agora.getProposal(id);
    console.log(prop)
    
  })
});