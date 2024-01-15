pragma solidity 0.8.13;

import "solmate/utils/ReentrancyGuard.sol";

contract Execute is ReentrancyGuard {
    struct PendingExecutionDetails {
        address receiver;
        uint32 siblingChainSlug;
        bytes payload;
    }

    // messageId => PendingExecutionDetails
    mapping(bytes32 => PendingExecutionDetails) public pendingExecutions;

    error InvalidExecutionRetry();

    function retryPayloadExecution(bytes32 msgId_) external nonReentrant {
        PendingExecutionDetails storage details = pendingExecutions[msgId_];

        if (details.receiver == address(0)) revert InvalidExecutionRetry();
        bool success = _execute(details.receiver, details.payload);

        if (success) _clearPayload(msgId_);
    }

    function _execute(
        address receiver_,
        bytes memory payload_
    ) internal returns (bool success) {
        (success, ) = receiver_.call(payload_);
    }

    function _cachePayload(
        bytes32 msgId_,
        uint32 siblingChainSlug_,
        address receiver_,
        bytes memory payload_
    ) internal {
        pendingExecutions[msgId_].receiver = receiver_;
        pendingExecutions[msgId_].siblingChainSlug = siblingChainSlug_;
        pendingExecutions[msgId_].payload = payload_;
    }

    function _clearPayload(bytes32 msgId_) internal {
        pendingExecutions[msgId_].receiver = address(0);
        pendingExecutions[msgId_].siblingChainSlug = 0;
        pendingExecutions[msgId_].payload = bytes("");
    }
}
