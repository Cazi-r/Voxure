// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VoteContract {
    // Kontrat sahibi
    address public owner;
    
    // Kaydedilmis oylarin hash'leri
    mapping(string => bool) private voteHashes;
    
    // Toplam oy sayisi
    uint256 public totalVotes;
    
    // Oyun kaydedildigi zaman tetiklenen olay
    event VoteCasted(string voteHash, uint256 timestamp);
    
    // Kontrat olusturuldugunda calisacak constructor
    constructor() {
        owner = msg.sender;
        totalVotes = 0;
    }
    
    // Sadece kontrat sahibinin cagirabileceği fonksiyonlar icin modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    
    // Oy verme fonksiyonu
    function castVote(string memory voteHash) public {
        // Ayni hash ile daha once oy verilip verilmedigini kontrol et
        require(!voteHashes[voteHash], "This vote has already been cast");
        
        // Oyu kaydet
        voteHashes[voteHash] = true;
        
        // Toplam oy sayisini artir
        totalVotes++;
        
        // Olay tetikle
        emit VoteCasted(voteHash, block.timestamp);
    }
    
    // Oyun daha once verilip verilmedigini kontrol et
    function verifyVote(string memory voteHash) public view returns (bool) {
        return voteHashes[voteHash];
    }
    
    // Toplam oy sayisini getir
    function getTotalVotes() public view returns (uint256) {
        return totalVotes;
    }
    
    // Sadece kontrat sahibinin cagirabileceği acil durum fonksiyonu
    function emergencyStop() public onlyOwner {
        selfdestruct(payable(owner));
    }
} 