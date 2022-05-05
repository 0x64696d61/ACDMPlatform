// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IACDMDao {
  function addProposal ( bytes memory callData, address recipient, string memory description ) external;
  function chairMan (  ) external view returns ( address );
  function finishProposal ( uint256 proposalId ) external;
  function incomeFundAddress (  ) external view returns ( address );
  function proposals ( uint256 ) external view returns ( string memory description, bytes memory callData, address recipient, int256 votes, uint256 endDate, uint256 votedCounter, bool result, bool status );
  function vote ( uint256 proposalId, bool choice ) external;
}
