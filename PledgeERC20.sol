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

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title PLEDGE Token
/// @dev ERC20 token with pledge mechanics where if a user pledges to limit their monthly transfers, they can transfer up to 1% of their balance each month without breaking the pledge.
/// @notice This is a token contract where holders can pledge to limit their monthly transfers.
/// @author MonkMatto
/// @custom:security-contact monkmatto@protonmail.com
/// @custom:disclaimer Not audited. Use at your own risk.
/// @custom:version v0.5.4
contract PLEDGE is ERC20, ERC20Permit, Ownable {

    /// @notice Constructor to create PLEDGE token with admin rights and permit functionality.
    constructor()
        ERC20("PLEDGE", "PLEDGE")
        ERC20Permit("PLEDGE")
        Ownable(msg.sender)
    {}

    bool public protectionsEnabled; // Whether protections are enabled or disabled
    address public feeReceiver; // The address that receives fees during the protection period
    address public uniswapRouterAddress = 0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD; // The address of the Uniswap Router for penalty exemptions, set to the Universal Router by default
    uint256 public nonAirdropTokensMinted; // The number of non-airdrop tokens minted
    uint256 public protectionStartTime; // The timestamp for calculating penalties
    uint256 public maxTokenSupply = 1_000_000_000 * (10 ** decimals()); // 1 billion tokens with 18 decimals
    uint256 public pledgeAirdropAmount = maxTokenSupply / 1_000; // 0.1% of maxTokenSupply
    uint256 public defaultPledgeOnePercent = pledgeAirdropAmount / 100; // 0.001% of maxTokenSupply
    uint256 private limitDivisor = 10; // The divisor for the pledge limit
    uint256 public constant PROTECTION_PERIOD = 125 minutes; // Period of time during which protections are enabled

    /// @dev Stores pledge data for each address
    /// @param status The status of the pledge: 0 for no pledge, 1 for active pledge, 2 for failed pledge, and 3 for completed pledge
    /// @param onePercent One percent of the pledged balance. For initial airdrops, this is kept at value 0 for optimization but is handled in other functions
    /// @param monthlyWindowStart The timestamp when the current monthly window started
    /// @param amountTransferredThisWindow Amount of tokens transferred in current window
    struct PledgeData {
        uint8 status;
        uint256 onePercent;
        uint256 monthlyWindowStart;
        uint256 amountTransferredThisWindow;
    }

    /// @dev Mapping of addresses to their pledge data
    mapping(address => PledgeData) public pledger;

    /// @dev Emitted when protections are toggled
    /// @param enabled Whether protections are enabled or disabled
    /// @param feeRecipient The address that receives penalties
    /// @param timestamp The timestamp of the event
    event ProtectionsToggled(bool enabled, address feeRecipient, uint256 timestamp);

    /// @dev Emitted when a penalty is charged
    /// @param user The address that was charged the penalty
    /// @param attemptedAmount The amount that was attempted to be transferred
    /// @param adjustedAmount The amount that was actually transferred after the penalty
    /// @param penalty The amount of the penalty sent to the feeReceiver
    event PenaltyCharged(address user, uint256 attemptedAmount, uint256 adjustedAmount, uint256 penalty);

    /// @dev Emitted when a new pledge is created
    /// @param pledgerAddress The address that created the pledge
    /// @param pledgerBalance The balance pledged
    event CreatedPledge(address indexed pledgerAddress, uint256 pledgerBalance);

    /// @dev Emitted when a pledge is broken due to excessive transfers
    /// @param pledgerAddress The address that broke their pledge
    /// @param transferredAmount The amount transferred that broke the pledge
    /// @param allowedTransferAmount The maximum amount that was allowed to transfer
    event BrokenPledge(address indexed pledgerAddress, uint256 transferredAmount, uint256 allowedTransferAmount);

    /// @dev Emitted when a pledge is completed
    /// @param pledgerAddress The address that completed their pledge
    event CompletedPledge(address indexed pledgerAddress);

    /// @notice Returns the time in seconds remaining in the current window for a given address.
    /// @dev Conveniently calculates time until the current window expires for a given address.
    /// @param _address The address to check.
    /// @return The time until the current window expires in seconds
    function getTimeRemainingInWindow(address _address) public view returns (uint256) {
        if (_isWindowExpired(_address)) {
            return 0;
        } else {
            return 30 days - (block.timestamp - pledger[_address].monthlyWindowStart);
        }
    }

    /// @notice Returns the amount that can be transferred by a given address at the current time without breaking the pledge. If there is no pledge active, it returns 0.
    /// @dev If the pledge is active, it checks if the current window has expired. If it has, it returns the full one percent, otherwise it returns the remaining amount that can be transferred in the current window.
    /// @param _address The address to check.
    /// @return The amount that can be transferred by the address at the current time without breaking the pledge.
    function getTransferableAmount(address _address) public view returns (uint256) {
        if (pledger[_address].status == 1) {
          uint256 transferable;
          uint256 onePercent = pledger[_address].onePercent;
          // Because airdrop accounts have default onePercent value of 0, we need to set it to defaultPledgeOnePercent
          if (onePercent == 0) {
              onePercent = defaultPledgeOnePercent;
          }
          if (_isWindowExpired(_address)) {
              transferable = onePercent;
          } else {
              transferable = onePercent - pledger[_address].amountTransferredThisWindow;
          }
          return transferable > balanceOf(_address) ? balanceOf(_address) : transferable;
        } else {
            return 0;
        }
    }

    /// @notice Returns the pledged balance of a given address.
    /// @dev If the pledge is active, it returns a very close approximation of the initially pledged balance, otherwise it returns 0.
    /// @param _address The address to check.
    /// @return pledgedBalance The pledged balance of the address.
    function getPledgedBalance(address _address) public view returns (uint256) {
        if (pledger[_address].status == 1) {
            uint256 onePercent = pledger[_address].onePercent;
            // Because airdrop accounts have default onePercent value of 0, we need to set it to defaultPledgeOnePercent
            if (onePercent == 0) {
                onePercent = defaultPledgeOnePercent;
            }
            uint256 pledgedBalance = onePercent * 100;
            return pledgedBalance;
        } else {
            return 0;
        }
    }

    /// @notice Returns the pledge data of a given address.
    /// @dev Returns the pledger status, balance, pledged balance, amount transferred this window, transferable amount, and time remaining in the current window (0 means the window has expired) for a given address.
    /// @param _address The address to check.
    /// @return The pledger status, balance, pledged balance, amount transferred this window, transferable amount, and time remaining in the current window for the address.
    function getPledgerData(address _address) external view returns (uint8, uint256, uint256, uint256, uint256, uint256) {
        return (
            pledger[_address].status,
            balanceOf(_address),
            getPledgedBalance(_address),
            pledger[_address].amountTransferredThisWindow,
            getTransferableAmount(_address),
            getTimeRemainingInWindow(_address)
        );
    }

    /// @notice Allows the owner to begin a temporary launch protection.
    /// @dev Allows the owner to enable protections for a set period of time and set the feeReceiver address.
    /// @param _feeReceiver The address that will receive penalties.
    function beginLaunchProtection(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
        protectionsEnabled = true;
        protectionStartTime = block.timestamp;
        emit ProtectionsToggled(protectionsEnabled, feeReceiver, block.timestamp);
    }

    /// @notice Allows the owner to disable launch protection.
    /// @dev After the protection window has ended, penalties are automatically bypassed, but the owner can disable protections to save gas on future transfers.
    function disableLaunchProtection() external onlyOwner {
        protectionsEnabled = false;
        emit ProtectionsToggled(protectionsEnabled, feeReceiver, block.timestamp);
    }

    /// @notice Allows the owner to set the Uniswap Router address.
    /// @dev Allows the owner to set the Uniswap Router address to prevent penalties on token distributions from the router.
    /// @dev It is set as state on deployment to the universal router address, but it can be updated on contract if needed.
    /// @param _uniswapRouterAddress The address of the Uniswap Router being used for token distributions during the protection period.
    function setUniswapRouterAddress(address _uniswapRouterAddress) external onlyOwner {
        uniswapRouterAddress = _uniswapRouterAddress;
    }

    /// @notice Allows the owner to set the amount that can be transferred without penalty during the protection period.
    /// @dev Sets the divisor for the defaultPledgerOnePercent value, which is used to calculate the base limit for transfers during the protection period.
    /// @param _limitDivisor The amount to divide defaultPledgerOnePercent by.
    function setLimitDivisor(uint256 _limitDivisor) external onlyOwner {
        require(_limitDivisor > 0, "INVALID_DIVISOR");
        limitDivisor = _limitDivisor;
    }

    /// @notice Allows the owner to airdrop tokens to pledgers.
    /// @dev Allows the owner to airdrop 1 million tokens or 0.1% of maxTokenSupply number of tokens to pledgers who have not yet pledged.
    /// @dev 90% of maxTokenSupply is reserved for airdrops, and 10% is reserved for non-airdrop tokens.
    /// @dev To save a lot of gas during airdrops, the 'onePercent' value in the pledge struct is not set and remains 0. Airdrop recipients will be the only accounts that have an active status and onePercent value of 0, so elsewhere in the contract we check for this and set it to defaultPledgeOnePercent.
    /// @param _addresses The addresses to airdrop tokens to.
    function airdropToPledgers(address[] calldata _addresses) external onlyOwner {
        uint256 len = _addresses.length;
        require(totalSupply() - nonAirdropTokensMinted + len * pledgeAirdropAmount <= maxTokenSupply * 90 / 100, "90% MAX SUPPLY AIRDROP CAP REACHED");
        for (uint256 i = 0; i < len; ) {          
            require(pledger[_addresses[i]].status == 0 && _addresses[i] != address(0), "INVALID PLEDGER");
            _mint(_addresses[i], pledgeAirdropAmount);
            pledger[_addresses[i]].status = 1;
            unchecked {
                i += 1;
            }
        }
    }

    /// @notice Allows the owner to mint tokens to a given address.
    /// @dev Allows the owner to mint up to 10% of maxTokenSupply amount of tokens to a given address.
    /// @dev 10% is reserved for non-airdrop tokens, and 90% of maxTokenSupply is reserved for airdrops.
    /// @param _to The address to mint tokens to.
    /// @param _amount The amount of tokens to mint.
    function mint(address _to, uint256 _amount) external virtual onlyOwner {
        require(nonAirdropTokensMinted + _amount <= maxTokenSupply / 10, "10% MAX SUPPLY NON-AIRDROP CAP REACHED");
        require(_amount > 0 && _amount + totalSupply() <= maxTokenSupply, "WRONG AMOUNT");
        require(_to != address(0), "INVALID ADDRESS");
        _mint(_to, _amount);
        nonAirdropTokensMinted += _amount;
    }

    /// @notice Allows an EOA to register a pledge on contract.
    /// @dev Allows EOA to record a pledge on contract if they own >= 100 base token units.
    /// @dev Accounts that have previously failed a pledge cannot pledge again.
    /// @dev Accounts that have an active pledge cannot reduce their pledge.
    /// @dev monthlyWindowStart is not set during pledging, but is updated during transfers.
    function pledge() external {
        address from = msg.sender;
        uint256 balance = balanceOf(from);
        require(pledger[from].status != 2, "HAS FAILED PLEDGE");
        require(balance >= 100, "MUST OWN >= 100 BASE UNITS");
        uint256 pledgedBalance = getPledgedBalance(from);
        require(balance >= pledgedBalance, "CANNOT REDUCE PLEDGE");
        pledger[from].onePercent = balance / 100;
        pledger[from].status = 1;
        emit CreatedPledge(from, balance);
    }

    /// @notice Allows EOA to complete a pledge.
    /// @dev Allows EOA to complete a pledge if they have no balance and have not failed a pledge.
    function completePledge() external {
        address from = msg.sender;
        require(pledger[from].status == 1, "NO ACTIVE PLEDGE");
        require(balanceOf(from) == 0, "MUST HAVE 0 BALANCE");
        pledger[from].status = 3;
        emit CompletedPledge(from);
    }

    /// @dev Overrides the internal _update function to add penalty logic and pledge status updates as required.
    /// @dev calls _updatePledgeStatus to update the pledge status for the sender.
    /// @param from The address tokens are being transferred from.
    /// @param to The address tokens are being transferred to.
    /// @param value The quantity of tokens being transferred.
    function _update(address from, address to, uint256 value) internal virtual override {
        if (
            protectionsEnabled &&
            block.timestamp <= protectionStartTime + PROTECTION_PERIOD &&
            value > defaultPledgeOnePercent / limitDivisor &&
            from != uniswapRouterAddress &&
            from != owner() &&
            from != address(0)
        ) {
            require(balanceOf(from) >= value, "ERC20: transfer amount exceeds balance");
            (uint256 adjustedAmount, uint256 penalty) = _calculatePenalty(value);
            if (penalty > 0) {
                super._update(from, feeReceiver, penalty);
                emit PenaltyCharged(tx.origin, value, adjustedAmount, penalty);
            }
            if (adjustedAmount > 0) {
                super._update(from, to, adjustedAmount);
            }
        } else {
            super._update(from, to, value);
        }
        if (pledger[from].status == 1) {
            _updatePledgeStatus(from, value);
        }
    }

    /// @dev Internal function that calculates the penalty for a given amount of tokens based on the time since launch and the amount over the limit.
    /// @dev These penalties are combined to create a penalty percentage that is applied to the excess amount.
    /// @param attemptedAmount The amount of tokens that were attempted to be transferred.
    /// @return adjustedAmount The amount of tokens that can be transferred after the penalty.
    /// @return penalty The amount of the penalty that will be charged.
    function _calculatePenalty(uint256 attemptedAmount) internal view returns (uint256 adjustedAmount, uint256 penalty) {     
        uint256 timeSinceLaunch = block.timestamp - protectionStartTime;
        uint256 baseLimit = defaultPledgeOnePercent / limitDivisor;
        
        // Only apply penalty to amount over baseLimit
        uint256 excessAmount = attemptedAmount - baseLimit;
        
        // Time factor: 100 at start, linearly decreases to 0
        uint256 timePenalty = ((PROTECTION_PERIOD - timeSinceLaunch) * 100) / PROTECTION_PERIOD;
        
        // Amount factor: 0 when at baseLimit, approaches 100 as amount increases
        uint256 amountPenalty = (excessAmount * 100) / (baseLimit + excessAmount);
        
        // Combined penalty percentage (0-100)
        uint256 penaltyPercent = (timePenalty * amountPenalty) / 100;
        
        // Apply penalty to excess amount
        uint256 penaltyAmount = (excessAmount * penaltyPercent) / 100;
        
        return (attemptedAmount - penaltyAmount, penaltyAmount);
    }

    /// @dev Internal function to update the pledge status for a given address.
    /// @param from The address tokens are being transferred from.
    /// @param amount The quantity of tokens being transferred.
    function _updatePledgeStatus(address from, uint256 amount) internal {
        if (_isWindowExpired(from)) {
            pledger[from].monthlyWindowStart = block.timestamp;
            pledger[from].amountTransferredThisWindow = amount;
        } else {
            pledger[from].amountTransferredThisWindow += amount;
        }
        uint256 onePercent = pledger[from].onePercent;
        // Because airdrop accounts have default onePercent value of 0, we need to set it to defaultPledgeOnePercent
        if (onePercent == 0) {
            onePercent = defaultPledgeOnePercent;
        }
        if (pledger[from].amountTransferredThisWindow > onePercent) {
            pledger[from].status = 2;
            emit BrokenPledge(from, pledger[from].amountTransferredThisWindow, onePercent);
        }
    }

    /// @dev Internal function to check if the pledge window has expired for a given address.
    /// @param _address The address to check.
    /// @return true if the pledge window has expired for the address.
    function _isWindowExpired(address _address) internal view returns (bool) {
        return (block.timestamp - pledger[_address].monthlyWindowStart) >= 30 days;
    }
}