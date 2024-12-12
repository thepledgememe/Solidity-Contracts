// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*                                                                                                                                                                                                                            
                                                    ..            ..                                                      
                                                    :.     :;:::;;:;::..                            .                     
                                                   .:.    .;xxxxXXXXx+;:..              .                                 
                                                   . .   :;X$&&$&&$$$X+;::...         ...                                 
                                                  .  ..:+xX$x:.....:+XXx++;::...........:.                                
                                                .+++++xX$X+.           .+XX++;;:::::...:;;:..........        .            
                                    .         . .+$&&&&x:.                .;Xx++;;;;::;;+++;;:::..:::......     .         
                              . . .  .     .      :::;:...                   :xXXx++;+++xXx;+;..... .        .            
            . ..  . .  ... .. . ..  ...              ...                   ....:X$XXxxxXXXXxx+x++;;;::............ .      
        .. ......... .. .......... .... .  .                              ...:...:X$$X$Xx+;;;;:...... ... ...... . ..     
        .........:......... .       ....... .                              .:;:.....$$X;.   ..;;;;;;;;;;;;:::..:......    
     .....::::;;:;+.;:.:...         ...::::.. . ...  .            .       ...:::.. ...;      .+xx++;+;+;+;;;;;;:;:::...   
    ..:..:+;;++;x++Xxxxxx++x;::...    ::;;;:;......... .          ....    ...:;;::..  ...    .;++xx++++xx+x++x++++;:..    
  ..::.;;+;++xx+XXX$XXXX$$$&&&$$$$$Xx::;++++;:;.............      .:;;;;::...:xx;:....  .;::::xXXXXXXXX$$$$$$$$XXxx;+:.   
 . :::;;+x+xXXXXXX$$$$$$$$$$$$&$$$$$&&$$$X+++;:......... ......    .+xxXxx::..;XX+;.......+x+$$$$$$Xx;:                   
  ..:;;;xXXX$$$&&$$XxxXxxxx+++;;+++++x$&&$Xx+;;;.....:.........    .:+xxxx;;:..+$Xx+::....;X$$.                           
                                    ;&$+;;X&$x+;;:..:::::;....:..   .+xxx++::...;$&Xx+;:..+;                              
                                    x$x.   +&&$XXx;;:;::;+;..:;;++;:;+x$x++;;....;$&$XXXXXX.                              
                                     +$;;:;X$+   .xXxxxx+++;..;xX$$X+;x$$x;+;;::.:;$&$$$$$;                               
                                        x$$$$X;...;$$+.  ;Xx+..;xXXxx++x$$Xx++;;:::+$$$$x.                                
                                           ;X$X$XX$Xx+;:;;x$$XXx$$Xxx+++x$$XXx+++;::.                                     
                                            ;XX&&&&xxXX$$$&$+:;X$&$Xxx+++x$&$Xx+;:::                                      
                                               ;&$Xxxx$$$&X++:.:XX$$XXxx+xx$&XXX++:                                       
                                                :X$$$$$&$x;xXX$$$$X$$XXXX++x.                                             
                                                    :+x$x++;+x$&$XXxX$XXx+;                                               
                                                       ;XX$$$$$$X++;.                                                     
                                                                                                                          
                                                                                                                          
                                                                                                                          
                                                                                                                          
                          ........    ......      ..........  .......        .:;:.:.  ..........                          
                          :;&X;;+X$;  ;+$X;;.     ;x$+;;;+Xx  :$$;;+X$+.   +$+:.;X&+  ;x$x;;;;XX                          
                            &+    +$   .Xx         ;X. .; ;+   XX    .xx. X$.     +:   :$: .: +x                          
                            &x   :Xx   .Xx         ;$XxX&      XX     ;$::$x           :$XxX$                             
                            &$xxx+.    .Xx     x.  ;X. .x  .   XX     ;$..$x   ;XX$$:  :$: .+  .                          
                            &+         .Xx    .&:  ;X.    +x   XX    :X+  x&;     Xx   :$:    +X                          
                          +x&$x+:     xx$$xxxxx&:.+X$XxxxxXx  ;$$xxxXX:    ;XX+;;x$+  +X$Xxxxx$X                          
*/

/// @notice This interface is needed to interact with the PLEDGE contract.
/// @dev the getPledgerData function returns the following values in this order: 
///       pledger status (0 == unpledged, 1 == active pledge, 2 == failed pledge, 3 == completed pledge), 
///       $PLEDGE balance, 
///       pledged $PLEDGE balance, 
///       $PLEDGE transferred this window, 
///       transferable $PLEDGE this window, 
///       time remaining in the current window.
interface PLEDGE {
    function getPledgerData(address _address) 
        external 
        view 
        returns (uint8, uint256, uint256, uint256, uint256, uint256);
}

/// @notice Importable contract with useful functions for interacting with the PLEDGE contract.
/// @dev Any function can be removed from the contract if it is not needed.
/// @author MonkMatto
/// @custom:security-contact monkmatto@protonmail.com
/// @custom:disclaimer Not audited. Use at your own risk.
/// @custom:version v0.0.1
contract PLEDGE_INTERACT {

    address public constant PLEDGE_CONTRACT = 0x910812c44eD2a3B611E4b051d9D83A88d652E2DD;

    /// @notice Gets the status of the addresses.
    /// @param _addresses Array of the addresses to check.
    /// @return An array of the statuses of the addresses.
    function getStatuses(address[] calldata _addresses) external view returns (uint8[] memory) {
        uint8[] memory statuses = new uint8[](_addresses.length);
        for (uint256 i = 0; i < _addresses.length; i++) {
            (uint8 status, , , , , ) = PLEDGE(PLEDGE_CONTRACT).getPledgerData(_addresses[i]);
            statuses[i] = status;
        }
        return statuses;
    }

    /// @notice Gets the total amount of $PLEDGE held by the addresses.
    /// @param _addresses Array of the addresses to check.
    /// @return The total amount of $PLEDGE held by the addresses.
    function aggregate_PLEDGE_Amount(address[] calldata _addresses) external view returns (uint256) {
        uint256 totalBalance;
        for (uint256 i = 0; i < _addresses.length; i++) {
            (, uint256 balance, , , , ) = PLEDGE(PLEDGE_CONTRACT).getPledgerData(_addresses[i]);
            totalBalance += balance;
        }
        return totalBalance;
    }

    /// @notice Gets the total amount of pledged $PLEDGE by the addresses.
    /// @param _addresses Array of the addresses to check.
    /// @return The total amount of pledged $PLEDGE by the addresses.
    function aggregatePledgedAmount(address[] calldata _addresses) external view returns (uint256) {
        uint256 totalPledgedBalance;
        for (uint256 i = 0; i < _addresses.length; i++) {
            (, , uint256 pledgedBalance, , , ) = PLEDGE(PLEDGE_CONTRACT).getPledgerData(_addresses[i]);
            totalPledgedBalance += pledgedBalance;
        }
        return totalPledgedBalance;
    }

    /// @notice Checks if the address has an active pledge.
    /// @param _address The address to check.
    /// @return True if the address has an active pledge, false otherwise.
    function requireActiveStatus(address _address) external view returns (bool) {
        (uint8 status, , , , , ) = PLEDGE(PLEDGE_CONTRACT).getPledgerData(_address);
        return status == 1;
    }

    /// @notice Checks if the address has a failed pledge.
    /// @param _address The address to check.
    /// @return True if the address has not failed a pledge, false otherwise.
    function requireNotFailedStatus(address _address) external view returns (bool) {
        (uint8 status, , , , , ) = PLEDGE(PLEDGE_CONTRACT).getPledgerData(_address);
        return status != 2;
    }

    /// @notice Checks if the address has a $PLEDGE token balance greater than or equal to the required balance.
    /// @param _requiredBalance The minimum balance required.
    /// @param _address The address to check.
    /// @return True if the address has a balance greater than or equal to the required balance, false otherwise.
    function hasMinimum_PLEDGE_Balance(uint256 _requiredBalance, address _address) external view returns (bool) {
        (, uint256 balance, , , , ) = PLEDGE(PLEDGE_CONTRACT).getPledgerData(_address);
        return balance >= _requiredBalance;
    }

    /// @notice Checks if the address has a pledgedBalance greater than or equal to the required pledgedBalance.
    /// @param _requiredPledgedBalance The minimum pledged balance required.
    /// @param _address The address to check.
    /// @return True if the address has a pledged balance greater than or equal to the required pledged balance, false otherwise.
    function hasMinimumPledgedBalance(uint256 _requiredPledgedBalance, address _address) external view returns (bool) {
        (, , uint256 pledgedBalance, , , ) = PLEDGE(PLEDGE_CONTRACT).getPledgerData(_address);
        return pledgedBalance >= _requiredPledgedBalance;
    }

    /// @notice Checks if the address has not transferred tokens in the current window.
    /// @param _address The address to check.
    /// @return True if the address has not transferred tokens in the current window, false otherwise.
    function hasNotTransferredInWindow(address _address) external view returns (bool) {
        (, , , uint256 amountTransferredThisWindow, , ) = PLEDGE(PLEDGE_CONTRACT).getPledgerData(_address);
        return amountTransferredThisWindow == 0;
    }

    /// @notice Checks that the address can transfer the amount without breaking the pledge.
    /// @param _attemptedTransferAmount The amount of tokens that the pledger is attempting to transfer.
    /// @param _address The address to check.
    /// @return True if the address can transfer the amount without breaking the pledge, false otherwise.
    function ensureTransferDoesntBreakPledge(uint256 _attemptedTransferAmount, address _address) external view returns (bool) {
        (uint8 status, , , , uint256 transferableAmount, ) = PLEDGE(PLEDGE_CONTRACT).getPledgerData(_address);
        if (status == 1) {
            return _attemptedTransferAmount <= transferableAmount;
        }
        return true;
    }

    /// @notice Checks that various requirements are met for a transaction to be allowed.
    /// @dev This single function can be used to check if the requirements are met for a transaction to be allowed.
    /// @param _requireActivePledge If true, the function will return false if the pledger does not have an active pledge.
    /// @param _forbidFailedPledge If true, the function will return false if the pledger has a failed pledge.
    /// @param _attemptedTransferAmount The amount of tokens that the pledger is attempting to transfer, this is used to check if an active pledger has enough transferable tokens in the current window. If they do not, the function will return false.
    /// @param _requiredPledgedBalance The minimum pledged balance required for function to return true.
    /// @param _requiredBalance The minimum balance required for function to return true.
    /// @param _requireZeroTransferInWindow If true, the function will return false if the pledger has already transferred tokens in the current window.
    /// @param _address The address to check.
    /// @return True if all requirements are met, false otherwise.
    function checkRequirements(
            bool _requireActivePledge, 
            bool _forbidFailedPledge, 
            uint256 _attemptedTransferAmount, 
            uint256 _requiredPledgedBalance, 
            uint256 _requiredBalance, 
            bool _requireZeroTransferInWindow, 
            address _address) 
            external view returns (bool) 
        {
            (uint8 status, uint256 balance, uint256 pledgedBalance, uint256 amountTransferredThisWindow, uint256 transferableAmount, ) = PLEDGE(PLEDGE_CONTRACT).getPledgerData(_address);
            if (_forbidFailedPledge && status == 2) {
                return false;
            }
            if (_requireActivePledge && status != 1) {
                return false;
            }
            if (status == 1) {
                if (_attemptedTransferAmount > transferableAmount) {
                    return false;
                }
            }
            if (pledgedBalance < _requiredPledgedBalance) {
                return false;
            }
            if (balance < _requiredBalance) {
                return false;
            }
            if (_requireZeroTransferInWindow && amountTransferredThisWindow != 0) {
                return false;
            }
            return true;
        }
}