//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LnbgLondonCoinMasterContract is Ownable {
    uint256 public proposalCount;
    uint256 public tokensForVote;

    struct Proposal {
        address proposer;
        string description;
        uint256 startTime;
        uint256 endTime;
        mapping(address => bool) votes;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    IERC20 public lnbgToken;

    mapping(uint256 => Proposal) public proposals;

    constructor(address _lnbgToken) {
        lnbgToken = IERC20(_lnbgToken);
        tokensForVote = 1 ether;
    }

    function changeVotingAmount(uint256 _tokens) public onlyOwner {
        tokensForVote = _tokens;
    }

    function submitProposal(string memory _description) public {
        require(
            bytes(_description).length > 0,
            "Description must not be empty"
        );

        proposalCount++;

        Proposal storage newProposal = proposals[proposalCount];
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + 60 days;
        newProposal.executed = false;
    }

    //check tokens here
    function vote(uint256 _proposalId, bool _supportsProposal) public {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp < proposal.endTime, "Voting period ended");
        require(!proposal.votes[msg.sender], "Already voted");
        require(
            lnbgToken.balanceOf(msg.sender) > tokensForVote,
            "You don't have Tokens for vote"
        );

        if (_supportsProposal) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        proposal.votes[msg.sender] = true;
    }

    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");
        if (proposal.yesVotes > proposal.noVotes) {
            proposal.executed = true;
        }
    }
}
