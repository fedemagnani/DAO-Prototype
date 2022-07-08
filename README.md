# DAO-Prototype

The proposed model of DAO is based on an architecture of three contracts in order to scale the logic of the methods in a transparent and democratic way preserving the governance system. 
The three contracts are: 

tokendDB3.sol → ERC-1155 of the DAO. It has the register of founders, associates and partenrs associating to each of them a token of representation. This contract is also where the addresses of AGORA and POLIS (the other two contracts) are stored.  AGORA address (proxy contract) is stored once and never again. POLIS address (logic contract) can be updated via dedicated governance proposal, once the source code is disclosed 

agora3.sol → Proxy contract. It stores variables that are editable via POLIS methods

polisV3.sol → Logic Contract. It contains methods to create, integrate and scrutinize proposals made by any member of the DAO. Just the author of the proposal has the capability of integrating the details of the proposal via the corresponidng method.
