pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    
    //DECLARATION
    address payable public owner; // account of person who deployed sc
    uint public personNumber; 
    uint public luckyNumber; // winner number
    uint public personCount  = 0; // #current participant
    uint public personLimit = 2; // #max participant
    uint public award = 6 ether;
    uint public price = 3 ether; // wei
    uint constt = 1048576;  // 2^20
    uint lastRun; // personLimit. Run 
    mapping (uint => address) public player; // participant's number => participant's address
    mapping (address => uint[]) public number; // participant's address => its numbers
    address[] giveback;

    event Updating(uint balance, uint personCount ); //will be triggered when new player join
    event Winner(uint luckyNumber, address winner); //will be triggered when lucky number is generated
    event NoWinner(uint value, uint luckyNumber);
    
    //MODIFIERS
    modifier onlyOwner(){ // for functions that are needed to be run by owner
        require(msg.sender == owner);
        _;
    }
    modifier checkLimit(){ // to terminate attending 
        require(personCount < personLimit);
        _;
    }
    modifier enoughPlayer(){
        require(personCount == personLimit); // to terminate lottery only when certain players are on the game
        _;
    }
    modifier enoughBalance(){
        require(getBalance() > 0 );
        _;
    }
    
    //CONSTRUCTOR
    constructor() {
        owner = payable(msg.sender);
    }
    
    //FUNCTIONS
    
    //SafeMath
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    
    //give number to participant, make transfer from participant to contract 
    function createPersonNumber(uint customNumber) public payable checkLimit { // test for negative value, RACE CONDITION!!!     
        for(uint i=0; i<5; i++){
            require (msg.value == price );
            uint temp = add(_random(),customNumber);
            personNumber =  uint(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, temp)))%constt); // generated random number for ech participant
            
            if (player[personNumber] == address(0)){ // unique number is found 
                deposit(); //payable(address(this)).transfer(msg.value); // send price to account of sc 
    
                number[msg.sender].push(personNumber);
    
                giveback.push(msg.sender);
                personCount++;
                player[personNumber] = msg.sender;
                lastRun = block.timestamp;
                emit Updating(getBalance(), personCount);
                break;
            }
            
            else{ // to prevent that more than one person have the same number, uniqueness 
             // payable(msg.sender).transfer(extra_cost); //   GIVE MONEY BACK to
                customNumber = add(customNumber, 1);
            }  
        }
    }
    
    function deposit() payable public { // DO NOT CALL IT OUT OF CONTRACT!!!
        // nothing to do!
    }

    function returnNumbers() public view returns(uint[] memory) {
        return number[msg.sender];
    }
     
    //find who win if exists and send money to related accounts that belong to winner and owner
    function getWinner() public onlyOwner enoughPlayer enoughBalance{ // CALL IT 3 MINUTES LATER FROM LAST TRANSFER
        if ((block.timestamp - lastRun) < 3 minutes){
             luckyNumber = _random();
             
             if ( player[luckyNumber] != address(0)){  // anonce winner and send money to winner and owner 
                 emit Winner(luckyNumber, player[luckyNumber]);
                 payable(player[luckyNumber]).transfer(award);
             }
             else { // nobody win 
                 emit NoWinner(2, luckyNumber);
             }
        }
        else { // to prevent abusing system, owner has to get "luckyNumber" in a certain time otherwise owner lost all money 
            emit NoWinner(1, 0);
            withdrawAllToOneAccount(); 
        } 
        owner.transfer(getBalance()); // no winner --> let all money into the owner account   OR   winner exist --> rest of them goes to the owner account
    }

    function getBalance() public view returns(uint) {
        return  address(this).balance; // this --> Smart contract
    }
     
    function _random() private view returns (uint) {
       return uint(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty)))%constt);
    } 
    
    //if number of players are less than expected, give money back
    function withdrawAllToOneAccount() public onlyOwner{ 
        uint i = 0;
        while(i < personCount){
            payable(giveback[i]).transfer(price - (1 ether));
            i++;
        }
    }
}




