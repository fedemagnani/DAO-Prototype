//SPDX-License-Identifier: MIT
pragma solidity >0.6.0;

interface IDBT{
    function getCurrentPolisAddress()external view returns (address);
    function isFounder(address)external view returns (bool);
    function isAssociate(address)external view returns (bool);
    function isPartner(address)external view returns (bool);
    function getNumberAssociates() external view returns (uint256);
    function setPolisAddress(address) external;
    function addAssociates(address[]memory)external;
    function addPartners(address[]memory)external; 
    function removeAssociates(address[]memory)external; 
    function removePartners(address[]memory)external; 
}

//Proposal Legend:
// ~ → none (meme)
// 0 → change Polis contract
// 1 → add members 
// 2 → add partners
// 3 → ostracism member -----------------> MUST BE INTEGRATED
// 4 → ostracism partner -----------------> MUST BE INTEGRATED
//----------------------ENDING OF GOVERNANCE PROPOSALS (we've a require that checks .typeOfProposal<=4)
// 5 → vote individual reputation

contract DiscoverBlockchainNewPolis{
    //Differently from previous version, we merge proposal and integrations
    // so now, there won't be a unique createProposal method, but there will be several ones
    //in this way, proposal structure remains (hopefully) homogenous across time and new proposal functions are added in future polis
    //We also remove the isReputationProp key, hope it is not a fatal edit
    //We remove also the "proposed address" field, since we may use directly the proposed address array

    //If it's not possible to add other variables, just write a function (in new polis) that calls hardcodedly the 
    //approved proposal in which there is the new variable
    //i.e.: 
    //function getWinnerTradingCompetition()public returns(address){
    //    return proposals[57].proposedAddresses[0];
    // }

    struct proposal{ 
        uint256 id;
        uint256 endingVote;
        uint256 inFavour;
        uint256 expiration; //for being scrutinized
        address author;
        uint8 typeOfProposal;
        bool isGovernanceProp; //if true, it is able to invoke leviathanic methods 
        bool[] status; // scrutinized → approved → executed

        address[] proposedAddresses; //without mapping, reputation proposal becomes a correspondence between proposedAddresses and proposedUints, more versatile for future type of vote proposals
        uint256[] proposedUints;
        bool[] proposedBools;
        string[] proposedObjects;
        //... add others?
    }
    
    //IN FUTURE VERSIONS, DO NOT ALTER THE PRE-EXISTENT ORDER OF VARIABLES AS DECLARED 

    address public addressDBT;
    uint256 public totalReputation;
    uint256 public totalProposals;
    uint256 public proposalTypes=6; //starting from zero
    mapping(uint256=>proposal) public proposals;
    mapping(uint256=>mapping(address=>bool)) hasVoted;
    mapping(address=>uint256) public reputation; //ANY address can be awarded via reputation, not necessarily associates or partners
    uint8 public reputationIncentiveVote = 1;
    uint8 public reputationMalusRejectedPropAuthor = 2;
    uint8 public reputationIncentiveUtils = 3; //generic incentive for calling functions
    uint8 public reputationIncentivePropAuthor = 5;
    bool public test;

    constructor(address _addressDBT){ 
        addressDBT=_addressDBT;
    }

    event newProposal(address,uint256);
    event proposalApproved(uint256);
    event proposalRejected(uint256);
    event proposalExecuted(uint256);
    event reputationTransferred(address,address,uint256);
    event newVote(address,uint256);

    function setAddressDBT(address _addressDBT) public {
        require(addressDBT==address(0),"DBT address already initialized");
        addressDBT=_addressDBT;
    }

    modifier onlyFounder() {
        require(IDBT(addressDBT).isFounder(msg.sender), "Caller is not a Founder");
        _;
    }
    modifier onlyAssociate() {
        require(IDBT(addressDBT).isAssociate(msg.sender), "Caller is not an Associate");
        _;
    }
    modifier onlyPartner() {
        require(IDBT(addressDBT).isPartner(msg.sender), "Caller is not a Partner");
        _;
    }

    modifier onlyApproved(uint256 _id) {
        require(proposals[_id].status[1],"Proposal not approved");
        _;
    }

    modifier preliminaryVotingCheck(uint _id){
        require(block.timestamp<proposals[_id].endingVote,"Voting has ended");
        require(!hasVoted[_id][msg.sender],"You've already voted");
        require(!proposals[_id].status[0],"Proposal has already been approved");
        hasVoted[_id][msg.sender]=true;
        _;
    }

    modifier preliminaryScrutinizingCheck(uint _id){
        require(block.timestamp>proposals[_id].endingVote,"Voting is still open");
        require(block.timestamp<proposals[_id].expiration,"Proposal expired");
        require(!proposals[_id].status[0],"Proposal already checked");
        proposals[_id].status[0]=true;
        _;
    }

    function _getNumberAssociates() internal view returns(uint256){
        return IDBT(addressDBT).getNumberAssociates();
    }

    function getProposalType(uint256 _typeOfProposal) public pure returns(string memory){ //edit this for future polis
    //Proposal Legend:
    // 0 → change Polis contract
    // 1 → add members 
    // 2 → add partners
    // 3 → ostracism member -----------------> MUST BE INTEGRATED
    // 4 → ostracism partner -----------------> MUST BE INTEGRATED
    // 5 → vote individual reputation
        return _typeOfProposal==0?"New polis":_typeOfProposal==1?"New associates":_typeOfProposal==2?"New partners":_typeOfProposal==3?"Associate ostracism":_typeOfProposal==4?"Partner Ostracism":_typeOfProposal==5?"Reputation voting":"None";
    }

    function getProposalStatus(uint256 _id) public view returns(string memory){
        //Progressive ternary operator
        return proposals[_id].status[2]?"Executed":proposals[_id].status[1]?"Approved":proposals[_id].status[0]?"Rejected":block.timestamp>proposals[_id].expiration?"Expired":"Pending";
    }

    //Retrieve everything from getProposal
    function getProposal(uint256 _id)public view returns(proposal memory){
        return proposals[_id];
    }

    function createBaseProposal(string[] memory _objects, uint256 _endingVote, uint256 _expiration) public onlyAssociate returns(proposal memory){
        require(_expiration>_endingVote,"Small expiration");
        //doesn't create proposal
        totalProposals++;
        uint256 id = totalProposals;
        proposal storage prop = proposals[id];
        prop.id = id;
        prop.status=[false,false,false];
        prop.expiration=_expiration;
        prop.endingVote=_endingVote;
        prop.author=msg.sender;
        prop.proposedObjects=_objects;
        emit newProposal(msg.sender,id);
        return prop;
    }

    function createFullProposal(string[] memory _objects, uint256 _endingVote, uint256 _expiration, bool _isGovernanceProp, uint8 _type, address[]memory _proposedAddresses, uint256[]memory _proposedUints, bool[]memory _proposedBools) public onlyAssociate returns(proposal memory){
        createBaseProposal(_objects, _endingVote, _expiration);
        require(_proposedAddresses.length ==1||_type!=0,"New polis proposal accepts only one address");
        uint256 id = totalProposals;
        proposal storage prop = proposals[id];
        prop.isGovernanceProp=_isGovernanceProp;
        prop.typeOfProposal=_type;
        prop.proposedAddresses=_proposedAddresses;
        prop.proposedUints=_proposedUints;
        prop.proposedBools=_proposedBools;
        return prop;
    }
    

    function _postVote(address _voter, uint256 _id) internal{
        proposals[_id].inFavour+=1;
        reputation[_voter]+=reputationIncentiveVote; //Increase reputation by one unit for having voted
        totalReputation+=reputationIncentiveVote;
        emit newVote(_voter,_id);
    }
    function _postScrutiny(address _scrutinizer, address _author, uint256 _id) internal{
        // reputationIncentiveScrutiny
        proposals[_id].status[1]=true; //→ APPROVED 
        reputation[_scrutinizer]+=reputationIncentiveUtils; //Increase reputation by one unit for having voted
        reputation[_author]+=reputationIncentivePropAuthor;
        totalReputation+=reputationIncentiveUtils+reputationIncentivePropAuthor;
        //No politics: we deliberately don't assign further reputation points to the author of the proposal
        emit proposalApproved(_id);
    }

    function _postScrutinyGovernance(address _scrutinizer, address _author, uint256 _id) internal{
        // reputationIncentiveScrutiny
        proposals[_id].status[1]=true; //→ APPROVED 

        //Interact with tokenDBsol according to proposalType
        if(proposals[_id].typeOfProposal==0){
            IDBT(addressDBT).setPolisAddress(proposals[_id].proposedAddresses[0]);
            _postExecutionProposal(msg.sender,_id);
        }
        if(proposals[_id].typeOfProposal==1){
            IDBT(addressDBT).addAssociates(proposals[_id].proposedAddresses);
            _postExecutionProposal(msg.sender,_id);
        }
        if(proposals[_id].typeOfProposal==2){
            IDBT(addressDBT).addPartners(proposals[_id].proposedAddresses);
            _postExecutionProposal(msg.sender,_id);
        }
        if(proposals[_id].typeOfProposal==3){
            IDBT(addressDBT).removeAssociates(proposals[_id].proposedAddresses);
            for (uint i=0;i<proposals[_id].proposedAddresses.length;i++){
                totalReputation-=reputation[proposals[_id].proposedAddresses[i]];
                reputation[proposals[_id].proposedAddresses[i]]=0;
            }
            _postExecutionProposal(msg.sender,_id);
        }
        if(proposals[_id].typeOfProposal==4){
            IDBT(addressDBT).removePartners(proposals[_id].proposedAddresses);
            for (uint i=0;i<proposals[_id].proposedAddresses.length;i++){
                totalReputation-=reputation[proposals[_id].proposedAddresses[i]];
                reputation[proposals[_id].proposedAddresses[i]]=0;
            }
            _postExecutionProposal(msg.sender,_id);
        }
        reputation[_scrutinizer]+=reputationIncentiveUtils; //Increase reputation by one unit for having voted
        reputation[_author]+=reputationIncentivePropAuthor;
        totalReputation+=reputationIncentiveUtils+reputationIncentivePropAuthor;
        //No politics: we deliberately don't assign further reputation points to the author of the proposal
        emit proposalApproved(_id);
    }

    
    function _postExecutionProposal(address _caller, uint256 _id) internal onlyApproved(_id){
        proposals[_id].status[2]=true; //→ EXECUTED
        reputation[_caller]+=reputationIncentiveUtils; //Increase reputation by one unit for having voted
        totalReputation+=reputationIncentiveUtils;
        emit proposalExecuted(_id);
    }

    function _postExecutionProposalNoReward(uint256 _id) internal onlyApproved(_id){
        proposals[_id].status[2]=true; //→ EXECUTED
        emit proposalExecuted(_id);
    }

    function voteGovernanceProposal(uint256 _id) public onlyAssociate preliminaryVotingCheck(_id){
        //good for proposals of type 0,1,2,3
        require(proposals[_id].isGovernanceProp,"Not a governance proposal");
        _postVote(msg.sender,_id);
    }

    function closeGovernanceProposal(uint256 _id) public preliminaryScrutinizingCheck(_id){ //no need to put it as onlyAssociate
        //good for proposals of type 0,1,2,3,4
        //these proposals modify tokenDB.sol
        //consider calling straightforwardly the method on tokenBD.sol, according to the ID case, so thee post execution functions will be invoked here, saving one contract call
        //thus, post execution functions must be internal and not public 
        require(proposals[_id].isGovernanceProp&&proposals[_id].typeOfProposal<=4,"Not a governance proposal");
        if(100*proposals[_id].inFavour>50*_getNumberAssociates()){
            _postScrutinyGovernance(msg.sender,proposals[_id].author,_id);
        }
        else{
            if(reputation[proposals[_id].author]>=reputationMalusRejectedPropAuthor){
                //in this way we compete for good quality proposals
                reputation[proposals[_id].author]-=reputationMalusRejectedPropAuthor;
                totalReputation-=reputationMalusRejectedPropAuthor;
            }
            emit proposalRejected(_id);
        }
    }

    function voteReputationProposal(uint256 _id, uint256 _championPosition) public onlyAssociate preliminaryVotingCheck(_id){ //since there isn't an handy indexOf, we shall vote champion according to the index
        //good for proposals of type 4 
        //Check for the typeOfProposal
        require(!proposals[_id].isGovernanceProp&&proposals[_id].typeOfProposal>4,"Not a non-governance proposal");
        require(msg.sender!=proposals[_id].proposedAddresses[_championPosition],"Self-voting");
        proposals[_id].proposedUints[_championPosition]+=1;
        _postVote(msg.sender,_id);
    }

    function closeReputationProposal(uint256 _id) public preliminaryScrutinizingCheck(_id){
        require(!proposals[_id].isGovernanceProp,"Not a non-governance proposal");
        for(uint i=0; i<proposals[_id].proposedAddresses.length; i++){
            //add the the number of received votes directly to the reputation score of the address
            reputation[proposals[_id].proposedAddresses[i]]+=proposals[_id].proposedUints[i];
        }
        _postScrutiny(msg.sender,proposals[_id].author,_id);
        _postExecutionProposalNoReward(_id);
    }

    function transferReputation(address _to, uint256 _amount) public {
        require(reputation[msg.sender]>=_amount,"Not enough reputation");
        unchecked {
            reputation[msg.sender] = reputation[msg.sender] - _amount;
        }
        reputation[_to] += _amount;
        emit reputationTransferred(msg.sender, _to, _amount);
    }

    function storeTest()public{
        test =true;
    }

    function getTest()public view returns(bool){
        return test;
    }

}