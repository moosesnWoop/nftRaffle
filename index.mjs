import {loadStdlib} from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib(process.env);

const startingBalance = stdlib.parseCurrency(100);

const [ accAlice, accBob ] =
  await stdlib.newTestAccounts(2, startingBalance);
console.log('Hello, Alice and Bob!');

console.log('Launching...');
const ctcAlice = accAlice.contract(backend);
const ctcBob = accBob.contract(backend, ctcAlice.getInfo());

console.log(`Creator is creating the NFT`);
const theNFT = await stdlib.launchToken(accAlice, "Mona Lisa", "NFT", {supply: 1}); //launching the token with details
const nftParams = {nftId: theNFT.id, numTickets: 10}; //nft parameters
await accBob.tokenAccept(nftParams.nftId); //we await for bob to opt-in to out nftId, we get the nft parameter 'nftId' which is .id of theNFT main token/NFT asset

const OUTCOME = ['Your number is not a match.', 'Your number matches!'];

const shared ={
  getNum: (numTickets) => {
  const num = Math.floor((Math.random() * numTickets) + 1);  //our backend fun which takes in the Uint (numTickets) will allow us to interact with that number from the contract. Here we are just generating a number for the numTicket - the actual function
  //num: we take a random number, times the ticket amount, with a Math.floor. plus 1 is for our 0 index, so we can have 1 and not 0.
  return num; //return the const to be retrieved in backend
},
  seeOutcome: (num) => {console.log(`The outcome is ${OUTCOME[num]}`);}
}

console.log('Starting backends...');
await Promise.all([
  backend.Alice(ctcAlice, {
    ...stdlib.hasRandom,
    ...shared,
    // implement Alice's interact object here
    startRaffle: () =>{
      console.log(`The raffle information is being sent to the contract`);
       return nftParams
       },
    seeHash: (value) => {
      console.log(`Winning number Hash: ${value}`)//here we take in the value and print it the console
    }, 
  }),

  backend.Bob(ctcBob, {
    ...stdlib.hasRandom,
    ...shared,
    // implement Bob's interact object here
    showNum: (num) => { console.log(`Your raffle number is: ${num}`)},
    seeWinner: (num) => {console.log(`The winning number is: ${num}`);} // we can use showNum instead, but for the sake of learning, we us seeWinner function shorthand to get the answer and post to console.log here
  }),
]);

console.log('Goodbye, Alice and Bob!');
