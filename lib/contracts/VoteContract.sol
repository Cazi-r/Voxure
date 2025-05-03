// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title VoteContract
/// @notice Oylama verilerini blockchain'de saklayan akıllı sözleşme
contract VoteContract {
    // Contract sahibi
    address public owner;
    
    // Anket ID'si => Seçenek => Oy sayısı
    mapping(string => mapping(uint256 => uint256)) private votes;
    
    // Kullanıcı ID'si => Anket ID'si => Oy verilen seçenek (-1: oy verilmemiş)
    mapping(string => mapping(string => int256)) private userVotes;
    
    // VoteCast olayı
    event VoteCast(string indexed surveyId, address indexed voter, uint256 optionIndex);
    
    // Constructor
    constructor() {
        owner = msg.sender;
    }
    
    // Yetki kontrolü
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /// @notice Kullanıcının bir ankete oy vermesini sağlar
    /// @param surveyId Anket ID'si
    /// @param optionIndex Seçenek numarası
    /// @param userId Kullanıcı ID'si
    function vote(string memory surveyId, uint256 optionIndex, string memory userId) public {
        // Kullanıcı daha önce oy vermiş mi kontrol et
        require(userVotes[userId][surveyId] == 0, "User already voted for this survey");
        
        // Oy kaydet
        votes[surveyId][optionIndex]++;
        userVotes[userId][surveyId] = int256(optionIndex + 1); // 1-tabanlı saklama (0 = hiç oy vermemiş)
        
        // Olayı bildir
        emit VoteCast(surveyId, msg.sender, optionIndex);
    }
    
    /// @notice Bir seçeneğin aldığı oy sayısını getirir
    /// @param surveyId Anket ID'si
    /// @param optionIndex Seçenek numarası
    /// @return Oy sayısı
    function getVoteCount(string memory surveyId, uint256 optionIndex) public view returns (uint256) {
        return votes[surveyId][optionIndex];
    }
    
    /// @notice Kullanıcının hangi seçeneğe oy verdiğini getirir
    /// @param surveyId Anket ID'si
    /// @param userId Kullanıcı ID'si
    /// @return Oy verilen seçenek (-1: oy verilmemiş)
    function getUserVote(string memory surveyId, string memory userId) public view returns (int256) {
        int256 voteValue = userVotes[userId][surveyId];
        if (voteValue == 0) {
            return -1; // Oy vermemiş
        }
        return voteValue - 1; // 0-tabanlı değere dönüştür
    }
} 