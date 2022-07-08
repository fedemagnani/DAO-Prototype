//SPDX-License-Identifier: MIT
pragma solidity >0.6.0;
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
interface IDBT{
    function getCurrentPolisAddress()external view returns (address);
}

contract DiscoverBlockchainAgora is ERC1967Proxy{
    constructor(address _tokenDbAddress, address _polisAddress) ERC1967Proxy(_polisAddress,abi.encodeWithSignature("setAddressDBT(address)", _tokenDbAddress)) {
        _changeAdmin(_tokenDbAddress);
        // assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        // _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _getDBTAddress()public view returns(address){
        return _getAdmin();
    }

    function _getPolisAddress()public view returns(address){
        //if the polis address has just been updated and noone has made a call to it via agora yet, it may return the old polis address 
        return _implementation();
    }
    
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }

    function _beforeFallback() internal virtual override{
        //We force the contract to be pointed to the current polis address
        address currentPolis = IDBT(_getDBTAddress()).getCurrentPolisAddress();
        if(currentPolis!=ERC1967Upgrade._getImplementation()){
            _upgradeTo(currentPolis);
        }
    }
}