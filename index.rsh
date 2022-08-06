'reach 0.1';

const amt = 1; //bind a const to the interger, so that it can be used instead of a int value mishap. 
const shared ={
  getNum: Fun([UInt], UInt),
  seeOutcome: Fun([UInt], Null)
}; //takes in a int (numtickets) and gives us an int to use on the front end

export const main = Reach.App(() => {
  const A = Participant('Alice', {
    // Specify Alice's interact interface here
    ...shared,
    ...hasRandom,
    startRaffle: Fun([],Object({nftId: Token, numTickets: UInt})),
    seeHash: Fun([Digest], Null)
  });
  const B = Participant('Bob', {
    // Specify Bob's interact interface here
    ...shared,
    showNum: Fun([UInt], Null), // takes in the numTickets and returns null
    seeWinner: Fun([UInt],Null) //Bob will see the answer, and if he wins or not
  });
  
  init();
  A.only(() =>{const {nftId, numTickets} = declassify(interact.startRaffle())
  const _winningNum = interact.getNum(numTickets); // the _ means that we can hide the const as a secret, and reach will keep the const a secret - Cyptographic Commitment Scheme
  const [_commitA,_saltA] = makeCommitment(interact, _winningNum); //here we are making a commitment and storing them in the const of _constA and _saltA as secrets - we are including the winning number as part of this commitment
  const commitA = declassify(_commitA); // here we are declassifying THE COMMITMENT (not the winning number) so that we are able to publish it to consensus.

  });
  // The first one to publish deploys the contract
  A.publish(nftId, numTickets, commitA); //the deployer publishes the NFT id as well as the number of tickets available. See startRaffle as an interaction object. We also publish the commitment of A
  A.interact.seeHash(commitA) // THe commitment is a digest type, not Uint type
  commit();
  A.pay([[amt, nftId]]); // the deployer is "paying" the NFT to the contract. 
  commit();

  unknowable(B,A(_winningNum,_saltA));//this runs a check with the verification engine, it want to check if B does not know A's commitment(the winning number and the salt)

  B.only(() =>{
    const myNum = declassify(interact.getNum(numTickets));
    interact.showNum(myNum); // this is good for conoole logging and debug, interact.function() allows us to interact with the backend and display the content, in this case myNum, on the frontend mjs. 
  })
  // The second one to publish always attaches
  B.publish(myNum);
  commit();
  // write your program here
  A.only(() => {
    const saltA = declassify(_saltA);
    const winningNum = declassify(_winningNum);
  })
  A.publish(saltA,winningNum);
  checkCommitment(commitA, saltA, winningNum); //here we are checking if alice did not change any of the values related to commitA after the commit
  B.interact.seeWinner(winningNum); //we only use this shorthand if we are not storing the value or returning a null - i.e. we want to interact to post to console.log
  
  const outcome = (myNum == winningNum ? 1 : 0); //create a const for the outcome, compare the two numbers with this operator will check and store as binary result
  transfer(amt, nftId).to(outcome == 0 ? A : B); // then we transfer the amt, with the id .to(the result of the outcome, either A or B).

  each([A,B], () => {interact.seeOutcome(outcome)}); //for each, show the result of the outcome
  
  commit();

  exit();
});
