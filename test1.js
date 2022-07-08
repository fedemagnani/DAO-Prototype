const { expect } = require("chai");

var DiscoverBlockchainToken;
var agora;
var polis;
var owner;
var owner2;
var caino;
var polisFounder1;
var polisFounder2;
var polisFutureAssociate;
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
  })
  it("We should be able to set polis and agora addresses (leviathanic)",async()=>{
      expect(await DiscoverBlockchainToken.setInitialAgoraAddress(agora.address));
      expect(await DiscoverBlockchainToken.setInitialPolisAddress(polis.address));
  })
  it("We should get access to DBT address via AGORA",async()=>{
    console.log(await agora.fallback("addressDBT"))
  })

  // it("We should be able to free the cages",async()=>{
  //     expect(await DiscoverBlockchainToken.openTheCages())
  // })
  // var id
  // var prop
  // it("We should be able to create separate instances of POLIS contract",async()=>{
  //   polisFounder1=polis.connect(owner);
  //   polisFounder2=polis.connect(owner2);
  //   polisFutureAssociate=polis.connect(futureAssociate);
  //   expect(true)
  // })
  // it("We should be able to create a base proposal (owner1)",async()=>{
  //     timestamp = Math.floor(Date.now()/1000);
  //     endingVote = timestamp+15;
  //     expiration = timestamp+500000000000;
  //     expect(await polisFounder1.createBaseProposal(["Questa proposta è un meme!"],endingVote,expiration))
  // })
  // it("We should be able to get access to the first proposal",async()=>{
  //   id = await polis.totalProposals();
  //   prop = await polis.getProposal(id);
  //   // console.log(prop)
  //   expect(!prop.status[0])
  // })
  // it("We should be able to create a full governance proposal (owner2)",async()=>{
  //   timestamp = Math.floor(Date.now()/1000);
  //   endingVote = timestamp+15;
  //   expiration = timestamp+500000000000;
  //   expect(await polisFounder2.createFullProposal(["Prima proposta governance piena!"],endingVote,expiration,true,1,[futureAssociate.address],[],[]))
  // })
  // it("We should be able to get access to the second proposal",async()=>{
  //   id = await polis.totalProposals();
  //   prop = await polis.getProposal(id);
  //   // console.log(prop)
  //   expect(!prop.status[0])
  // })
  // it("We should be able to vote the governance proposal (owner1 and owner2)",async()=>{
  //   expect(await polisFounder1.voteGovernanceProposal(id))
  //   expect(await polisFounder2.voteGovernanceProposal(id))
  // })
  // it("We should not be able to vote the governance proposal again",async()=>{
  //   try{
  //     await polis.voteGovernanceProposal(id)
  //   }catch(e){
  //     expect(true)
  //   }
  // })
  // it("We should have gained some reputation",async()=>{
  //   expect((await polis.reputation[owner.address])>0)
  // })
  // it("We should incurr in error if we try to add members while proposal is pending",async()=>{
  //   //This because we're not the leviathan
  //   try{
  //       await DiscoverBlockchainToken.addAssociates(id)
  //   }catch(e){
  //       // console.log(e)
  //       expect(true)
  //   }
  // })

  // it("We wait the end of the voting time-window",async()=>{
  //   var smallT = Math.floor(Date.now()/1000)
  //   expect(await waitFor(endingVote>smallT?(endingVote-smallT)*1000:0))
  //   // expect(await waitFor(7000))
  // })

  // it("Now we should be able to approve the proposal (owner2)",async()=>{
  //   expect(await polisFounder2.closeGovernanceProposal(id))
  //   var proposal = await polis.proposals(id);
  //   console.log(await polis.getProposalStatus(id))
  //   // console.log(proposal);
  // })

  // it("Associates, assemble!",async()=>{
  //   expect(await DiscoverBlockchainToken.associates(futureAssociate.address))
  // })

  // it("We expect new associate to claim tokens",async()=>{
  //   expect(await dbtFutureAssociate.claimToken())
  // })

  // it("We expect balance of the new associate to be positive",async()=>{
  //   expect((await dbtFutureAssociate.balanceOf(futureAssociate.address,1))>0)
  // })

  // it("We expect the new associate to create a proposal for being ostracized (lmao wtf)",async()=>{
  //   timestamp = Math.floor(Date.now()/1000);
  //   endingVote = timestamp+15;
  //   expiration = timestamp+500000000000;
  //   expect(await polisFutureAssociate.createFullProposal(["Sarò ostracizzato nuu"],endingVote,expiration,true,3,[futureAssociate.address],[],[]))
  // })
  // it("We should be able to get access to the second proposal",async()=>{
  //   id = await polis.totalProposals();
  //   prop = await polis.getProposal(id);
  //   // console.log(prop)
  //   expect(!prop.status[0])
  // })

  // it("We should be able to vote the governance proposal (owner1 and new associate)",async()=>{
  //   expect(await polisFounder1.voteGovernanceProposal(id))
  //   expect(await polisFutureAssociate.voteGovernanceProposal(id))
  // })

  // it("We expect the new associate to have gained some reputation",async()=>{
  //   expect((await polis.reputation[futureAssociate.address])>0)
  // })

  // it("We wait the end of the voting time-window",async()=>{
  //   var smallT = Math.floor(Date.now()/1000)
  //   expect(await waitFor(endingVote>smallT?(endingVote-smallT)*1000:0))
  //   // expect(await waitFor(7000))
  // })

  // it("Now we should be able to approve the proposal (owner2)",async()=>{
  //   expect(await polisFounder2.closeGovernanceProposal(id))
  //   var proposal = await polis.proposals(id);
  //   console.log(await polis.getProposalStatus(id))
  //   // console.log(proposal);
  // })

  // it("Ex associate shall be gone",async()=>{
  //   var isAssociate = await DiscoverBlockchainToken.associates(futureAssociate.address);
  //   var balance = await DiscoverBlockchainToken.balanceOf(futureAssociate.address,1);
  //   var rep = await polis.reputation(futureAssociate.address);
  //   var hasClaimed = await DiscoverBlockchainToken.tokenClaimedList(futureAssociate.address,1);
  //   expect(!isAssociate)
  //   expect(balance==0);
  //   expect(rep==0);
  //   expect(!hasClaimed);
  // })
  
  // it("Ex associate shouldn't be able to claim token",async()=>{
  //   try{
  //     await dbtFutureAssociate.claimToken()
  //   }catch(e){
  //     expect(true)
  //   }
  // })

});

describe("DISCOVER-BLOCKCHAIN-DAO-V2", function () {
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
    polis = await POLIS.deploy(DiscoverBlockchainToken.address)
  })
  it("We should be able to set polis and agora addresses (leviathanic)",async()=>{
      expect(await DiscoverBlockchainToken.setInitialAgoraAddress(polis.address));
      expect(await DiscoverBlockchainToken.setInitialPolisAddress(polis.address));
  })
  it("We should be able to free the cages",async()=>{
      expect(await DiscoverBlockchainToken.openTheCages())
  })
  var id
  var prop
  it("We should be able to create separate instances of POLIS contract",async()=>{
    polisFounder1=polis.connect(owner);
    polisFounder2=polis.connect(owner2);
    polisFutureAssociate=polis.connect(futureAssociate);
    expect(true)
  })
  it("We should be able to create a base proposal (owner1)",async()=>{
      timestamp = Math.floor(Date.now()/1000);
      endingVote = timestamp+15;
      expiration = timestamp+500000000000;
      expect(await polisFounder1.createBaseProposal(["Questa proposta è un meme!"],endingVote,expiration))
  })
  it("We should be able to get access to the first proposal",async()=>{
    id = await polis.totalProposals();
    prop = await polis.getProposal(id);
    // console.log(prop)
    expect(!prop.status[0])
  })
  it("We should be able to create a full governance proposal (owner2)",async()=>{
    timestamp = Math.floor(Date.now()/1000);
    endingVote = timestamp+15;
    expiration = timestamp+500000000000;
    expect(await polisFounder2.createFullProposal(["Prima proposta governance piena!"],endingVote,expiration,true,1,[futureAssociate.address],[],[]))
  })
  it("We should be able to get access to the second proposal",async()=>{
    id = await polis.totalProposals();
    prop = await polis.getProposal(id);
    // console.log(prop)
    expect(!prop.status[0])
  })
  it("We should be able to vote the governance proposal (owner1 and owner2)",async()=>{
    expect(await polisFounder1.voteGovernanceProposal(id))
    expect(await polisFounder2.voteGovernanceProposal(id))
  })
  it("We should not be able to vote the governance proposal again",async()=>{
    try{
      await polis.voteGovernanceProposal(id)
    }catch(e){
      expect(true)
    }
  })
  it("We should have gained some reputation",async()=>{
    expect((await polis.reputation[owner.address])>0)
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
    expect(await polisFounder2.closeGovernanceProposal(id))
    var proposal = await polis.proposals(id);
    console.log(await polis.getProposalStatus(id))
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
    expect(await polisFutureAssociate.createFullProposal(["Sarò ostracizzato nuu"],endingVote,expiration,true,3,[futureAssociate.address],[],[]))
  })
  it("We should be able to get access to the second proposal",async()=>{
    id = await polis.totalProposals();
    prop = await polis.getProposal(id);
    // console.log(prop)
    expect(!prop.status[0])
  })

  it("We should be able to vote the governance proposal (owner1 and new associate)",async()=>{
    expect(await polisFounder1.voteGovernanceProposal(id))
    expect(await polisFutureAssociate.voteGovernanceProposal(id))
  })

  it("We expect the new associate to have gained some reputation",async()=>{
    expect((await polis.reputation[futureAssociate.address])>0)
  })

  it("We wait the end of the voting time-window",async()=>{
    var smallT = Math.floor(Date.now()/1000)
    expect(await waitFor(endingVote>smallT?(endingVote-smallT)*1000:0))
    // expect(await waitFor(7000))
  })

  it("Now we should be able to approve the proposal (owner2)",async()=>{
    expect(await polisFounder2.closeGovernanceProposal(id))
    var proposal = await polis.proposals(id);
    console.log(await polis.getProposalStatus(id))
    // console.log(proposal);
  })

  it("Ex associate shall be gone",async()=>{
    var isAssociate = await DiscoverBlockchainToken.associates(futureAssociate.address);
    var balance = await DiscoverBlockchainToken.balanceOf(futureAssociate.address,1);
    var rep = await polis.reputation(futureAssociate.address);
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

});

// describe("DISCOVER-BLOCKCHAIN-DAO-V2", function () {
//   it("Deployment should assign owner to founders and associate", async function () {
//     [owner,owner2,caino] = await ethers.getSigners();
//     futureAssociate=caino;
//     // console.log(owner.address)
//     const Token = await ethers.getContractFactory("DiscoverBlockchainToken");
//     DiscoverBlockchainToken = await Token.deploy([owner.address,owner2.address]);
//     dbtFutureAssociate = DiscoverBlockchainToken.connect(futureAssociate);

//     expect(await DiscoverBlockchainToken.associates(owner.address));
//     expect(await DiscoverBlockchainToken.founders(owner2.address));
//   });
//   it("We should be able to claim tokens",async()=>{
//     expect(await DiscoverBlockchainToken.claimToken());
//   })
//   it("We should be able to have a positive balance of the first two tokens, null of the third",async()=>{
//     expect(await DiscoverBlockchainToken.balanceOf(owner.address,0)>0);
//     expect(await DiscoverBlockchainToken.balanceOf(owner2.address,1)>0);
//     expect(await DiscoverBlockchainToken.balanceOf(owner.address,1)==0);
//   })
//   it("Deployment of POLIS should be good",async()=>{
//     // const AGORA = await ethers.getContractFactory("AgoraDiscoverBlockchain");
//     //we skip deployment of agora, we consider polis contract both as AGORA and POLIS
//     const POLIS = await ethers.getContractFactory("DiscoverBlockchainPolis");
//     polis = await POLIS.deploy(DiscoverBlockchainToken.address)
//   })
//   it("We should be able to set polis and agora addresses (leviathanic)",async()=>{
//       expect(await DiscoverBlockchainToken.setInitialAgoraAddress(polis.address));
//       expect(await DiscoverBlockchainToken.setInitialPolisAddress(polis.address));
//   })
//   it("We should be able to free the cages",async()=>{
//       expect(await DiscoverBlockchainToken.openTheCages())
//   })
//   var id
//   var prop
//   it("We should be able to create separate instances of POLIS contract",async()=>{
//     polisFounder1=polis.connect(owner);
//     polisFounder2=polis.connect(owner2);
//     polisFutureAssociate=polis.connect(futureAssociate);
//     expect(true)
//   })
//   it("We should be able to create a base proposal (owner1)",async()=>{
//       timestamp = Math.floor(Date.now()/1000);
//       endingVote = timestamp+15;
//       expiration = timestamp+500000000000;
//       expect(await polisFounder1.createBaseProposal(["Questa proposta è un meme!"],endingVote,expiration))
//   })
//   it("We should be able to get access to the first proposal",async()=>{
//     id = await polis.totalProposals();
//     prop = await polis.getProposal(id);
//     // console.log(prop)
//     expect(!prop.status[0])
//   })
//   it("We should be able to create a full governance proposal (owner2)",async()=>{
//     timestamp = Math.floor(Date.now()/1000);
//     endingVote = timestamp+15;
//     expiration = timestamp+500000000000;
//     expect(await polisFounder2.createFullProposal(["Prima proposta governance piena!"],endingVote,expiration,true,1,[futureAssociate.address],[],[]))
//   })
//   it("We should be able to get access to the second proposal",async()=>{
//     id = await polis.totalProposals();
//     prop = await polis.getProposal(id);
//     // console.log(prop)
//     expect(!prop.status[0])
//   })
//   it("We should be able to vote the governance proposal (owner1 and owner2)",async()=>{
//     expect(await polisFounder1.voteGovernanceProposal(id))
//     expect(await polisFounder2.voteGovernanceProposal(id))
//   })
//   it("We should not be able to vote the governance proposal again",async()=>{
//     try{
//       await polis.voteGovernanceProposal(id)
//     }catch(e){
//       expect(true)
//     }
//   })
//   it("We should have gained some reputation",async()=>{
//     expect((await polis.reputation[owner.address])>0)
//   })

//   it("We should incurr in error if we try to add members while proposal is pending",async()=>{
//     try{
//         await DiscoverBlockchainToken.addAssociates(id)
//     }catch(e){
//         // console.log(e)
//         expect(true)
//     }
//   })

//   it("We wait the end of the voting time-window",async()=>{
//     var smallT = Math.floor(Date.now()/1000)
//     expect(await waitFor(endingVote>smallT?(endingVote-smallT)*1000:0))
//     // expect(await waitFor(7000))
//   })

//   it("Now we should be able to approve the proposal (owner2)",async()=>{
//     expect(await polisFounder2.closeGovernanceProposal(id))
//     var proposal = await polis.proposals(id);
//     console.log(await polis.getProposalStatus(id))
//     // console.log(proposal);
//   })

//   it("We should be able to let our friends in!",async()=>{
//     expect(await DiscoverBlockchainToken.addAssociates(id))
//   })

//   it("Associates, assemble!",async()=>{
//     expect(await DiscoverBlockchainToken.associates(futureAssociate.address))
//   })

//   it("We expect new associate to claim tokens",async()=>{
//     expect(await dbtFutureAssociate.claimToken())
//   })

//   it("We expect balance of the new associate to be positive",async()=>{
//     expect((await dbtFutureAssociate.balanceOf(futureAssociate.address,1))>0)
//   })

//   it("We expect the new associate to create a proposal for being ostracized (lmao wtf)",async()=>{
//     timestamp = Math.floor(Date.now()/1000);
//     endingVote = timestamp+15;
//     expiration = timestamp+500000000000;
//     expect(await polisFutureAssociate.createFullProposal(["Sarò ostracizzato nuu"],endingVote,expiration,true,3,[futureAssociate.address],[],[]))
//   })
//   it("We should be able to get access to the second proposal",async()=>{
//     id = await polis.totalProposals();
//     prop = await polis.getProposal(id);
//     // console.log(prop)
//     expect(!prop.status[0])
//   })
//   it("We should be able to vote the governance proposal (owner1 and new associate)",async()=>{
//     expect(await polisFounder1.voteGovernanceProposal(id))
//     expect(await polisFutureAssociate.voteGovernanceProposal(id))
//   })
//   it("We expect the new associate to have gained some reputation",async()=>{
//     expect((await polis.reputation[futureAssociate.address])>0)
//   })
//   it("We wait the end of the voting time-window",async()=>{
//     var smallT = Math.floor(Date.now()/1000)
//     expect(await waitFor(endingVote>smallT?(endingVote-smallT)*1000:0))
//     // expect(await waitFor(7000))
//   })
//   it("Now we should be able to approve the proposal (owner2)",async()=>{
//     expect(await polisFounder2.closeGovernanceProposal(id))
//     var proposal = await polis.proposals(id);
//     console.log(await polis.getProposalStatus(id))
//     // console.log(proposal);
//   })
// });

// describe("DISCOVER-BLOCKCHAIN-DAO", function () {
//   it("Deployment should assign founder to founders and associate", async function () {
//     [owner] = await ethers.getSigners();
//     // console.log(owner.address)
//     const Token = await ethers.getContractFactory("DiscoverBlockchainToken");
//     DiscoverBlockchainToken = await Token.deploy([owner.address]);
//     expect(await DiscoverBlockchainToken.associates(owner.address));
//     expect(await DiscoverBlockchainToken.founders(owner.address));
//   });
//   it("We should be able to claim tokens",async()=>{
//     expect(await DiscoverBlockchainToken.claimToken());
//   })
//   it("We should be able to have a positive balance of the first two tokens, null of the third",async()=>{
//     expect(await DiscoverBlockchainToken.balanceOf(owner.address,0)>0);
//     expect(await DiscoverBlockchainToken.balanceOf(owner.address,1)>0);
//     expect(await DiscoverBlockchainToken.balanceOf(owner.address,1)==0);
//   })
//   it("Deployment of POLIS should be good",async()=>{
//     // const AGORA = await ethers.getContractFactory("AgoraDiscoverBlockchain");
//     //we skip deployment of agora, we consider polis contract both as AGORA and POLIS
//     const POLIS = await ethers.getContractFactory("PolisDiscoverBlockchain");
//     polis = await POLIS.deploy(DiscoverBlockchainToken.address)
//   })
//   it("We should be able to set polis and agora addresses (leviathanic)",async()=>{
//       expect(await DiscoverBlockchainToken.setInitialAgoraAddress(polis.address));
//       expect(await DiscoverBlockchainToken.setInitialPolisAddress(polis.address));
//   })
//   it("We should be able to free the cages",async()=>{
//       expect(await DiscoverBlockchainToken.openTheCages())
//   })
//   var timestamp = Math.floor(Date.now()/1000);
//   var endingVote = timestamp+10;
//   var expiration = timestamp+5000000;
//   var id
//   it("We should be able to create a proposal",async()=>{
//       expect(await polis.createProposal("Aggiungiamo mio indirizzo di nuovo!",1,true,false,endingVote,expiration))
//   })
  
//   it("We should be able to integrate the proposal",async()=>{
//     id = await polis.totalProposals()
//     expect(await polis.integrateProposalArrayAddress(id,[owner.address]))
//   })
//   it("We should be able to vote the proposal",async()=>{
//     expect(await polis.voteGovernanceProposal(id))
//   })
//   it("We should incurr in error if we try to add member with the pending proposal",async()=>{
//     try{
//         await DiscoverBlockchainToken.addAssociates(id)
//     }catch(e){
//         // console.log(e)
//         expect(true)
//     }
//   })
//   it("We wait the end of the voting time-window",async()=>{
//     expect(await waitFor(4000))
//   })

//   it("Now we should be able to approve the proposal",async()=>{
//     expect(await polis.closeGovernanceProposal(id))
//     var proposal = await polis.proposals(id);
//     console.log(proposal);
//     console.log(await polis.totalProposals())
//     // var integration = await polis.integrations(id);
//     console.log(await polis.integrations(id-1))
//     console.log(await polis.integrations(id))
//     console.log(await polis.integrations(id+1))
//   })
 
// });
