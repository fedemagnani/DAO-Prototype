//SPDX-License-Identifier: MIT
pragma solidity >0.6.0;

interface IDBT{
    function getCurrentPolisAddress()external view returns (address);
}

contract DiscoverBlockchainAgora{
    //You need to hardcode the contract of tokenDB, storing variables is super risky

    function _dbtAddress()public pure returns(address){
        return address(0); //HARDCODE HERE DBT ADDRESS!
    }

    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function _implementation() internal view virtual returns (address){ //will delegate the calls to the current Polis address
        return IDBT(_dbtAddress()).getCurrentPolisAddress();
    }

    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    //Here if no function on the Polis contract matches the calldata 
    fallback() external payable virtual {
        _fallback();
    }

    //Here if calldata is empty
    receive() external payable virtual {
        _fallback();
    }

    //Consider using a hook in order to handle upcoming requests
    function _beforeFallback() internal virtual {}
}