# Solidity-Contracts
The $PLEDGE ERC20 contract incorporates social experimental aspects into a standard ERC-20 contract (OpenZeppelin v5). While the $PLEDGE contract **can never** limit a users ability to transact their tokens, it tracks if a user pledges on-chain and upholds their pledge as they **transfer** their tokens.

## Ethereum Mainnet CA
`0x910812c44eD2a3B611E4b051d9D83A88d652E2DD`

## ANY TRANSFER-OUT OF TOKENS COUNTS!
Initial Pledgers are airdropped tokens and are automatically pledged on-chain in the process, and anyone with just a small amount of $PLEDGE can also pledge on-chain. In all cases, the pledging account's balance of tokens is their 'Pledged Balance' and 1% of that amount becomes their '1% transferrable maximum' (AKA *1% max*). An account's 1% max is in respect to its unique 30 day window, and the 1% max does not change as the account's token balance is reduced or increased. An account's 1% max is fixed and can only change if the account re-pledges on-chain.

If a pledged account transfers more than their 1% max within a 30 day period, that account is forever recorded as having FAILED the pledge. There is no undo or correctable action if an account fails, and an account with a FAILED pledge cannot repledge. If an account successfully reaches a balance of 0 tokens while still having an ACTIVE pledge, that account can call a function on the contract to COMPLETE the pledge. Once completed, if so desired, the account could re-pledge.

A Pledger's 30 day window is tracked by a timestamp specific to that account, and these windows are dynamic as the account trades over time. These windows are not set automatically by airdrops or on-chain pledges, but instead are set and reset when transfers out of the account occur. If the last stored timestamp for an account is more than 30 days old, a new timestamp is recorded.

The smart contract features NatSpec documentation and has a number of 'convenience' functions that allow users, apps, *and other smart contracts* to easily access vital pledger data, like an account's pledge status, time left in their 30 day window, the maximum tokens that can be safely transferred while maintaining their pledge, and more. The contract is designed to be robust, simple, and flexible for potential inclusion in DApps or extension by other contracts.

## Key Functions for Integration
The getPledgerData(_address) funtion allows an app or contract a single call to retrieve the most relevant data regarding a pledger:
```
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
```

## Interaction Contract
I've written an importable example contract that can be used to interact with The Pledge ERC-20 contract. You can use it as is, or delete any functions you don't want to use. Note that you have to keep the interface to use any of the functions.
