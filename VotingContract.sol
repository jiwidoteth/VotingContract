// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract VotingContract {
    address public manager;
    bool public votingOpen;
    
    struct Topic {
        string title;
        string description;
        mapping(address => bool) hasVoted;
    }
    
    mapping(uint256 => Topic) public topics;
    uint256 public topicCount;
    
    mapping(address => uint256) public scores; // 管理积分
    
    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can perform this action.");
        _;
    }
    
    event TopicAdded(uint256 topicId, string title, string description);
    event VotingStarted(uint256 topicId);
    event VotingClosed(uint256 topicId);
    event VoteCasted(uint256 topicId, address voter);
    event RewardSent(address recipient, uint256 amount);
    
    constructor() {
        manager = msg.sender;
    }
    
    function setManager(address _manager) external onlyManager {
        manager = _manager;
    }
    
    function addTopic(string calldata _title, string calldata _description) external onlyManager {
        uint256 topicId = topicCount++;
        Topic storage newTopic = topics[topicId];
        newTopic.title = _title;
        newTopic.description = _description;
        emit TopicAdded(topicId, _title, _description);
    }
    
    function startVoting(uint256 _topicId) external onlyManager {
        require(!votingOpen, "Voting is already open.");
        require(_topicId < topicCount, "Invalid topic ID.");
        
        votingOpen = true;
        emit VotingStarted(_topicId);
    }
    
    function closeVoting(uint256 _topicId) external onlyManager {
        require(votingOpen, "Voting is not open.");
        require(_topicId < topicCount, "Invalid topic ID.");
        
        Topic storage topic = topics[_topicId];
        require(bytes(topic.title).length > 0, "Topic does not exist.");
        
        votingOpen = false;
        emit VotingClosed(_topicId);
        
        settleVotes(_topicId);
    }
    
    function vote(uint256 _topicId) external {
        require(votingOpen, "Voting is not open.");
        require(_topicId < topicCount, "Invalid topic ID.");
        
        Topic storage topic = topics[_topicId];
        require(bytes(topic.title).length > 0, "Topic does not exist.");
        require(!topic.hasVoted[msg.sender], "Already voted for this topic.");
        
        topic.hasVoted[msg.sender] = true;
        emit VoteCasted(_topicId, msg.sender);
        
        // 增加积分
        scores[msg.sender]++;
    }
    
    function settleVotes(uint256 _topicId) internal {
        Topic storage topic = topics[_topicId];
        uint256 rewardAmount = 10; // 设置奖励数量
        
        for (uint256 i = 0; i < topicCount; i++) {
            if (topic.hasVoted[msg.sender]) {
                // 奖励正确投票的人
                scores[msg.sender] += rewardAmount;
                emit RewardSent(msg.sender, rewardAmount);
            }
        }
    }
}
