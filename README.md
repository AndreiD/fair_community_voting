# A Fair Community Voting System

**Blockchain + Voting + Procedures = Win**

### Problem:

Small communities (<1000 members) can benefit greatly from the simplicity of e-voting. The only way blockchain and smart contracts can help in voting is by having additional procedures in place that ensure anonymity and transparency.

### This repo:

Quadratic_voting should help. [A q](https://en.wikipedia.org/wiki/Quadratic_voting) - check the applications

### The procedures:

The following procedures must be stricly respected:

1. Random registration codes (e.g., 6 uppercase letters) are generated and printed. Lottery type of scratch paint can be applied over the registration code to ensure it cannot be seen.
2. These registration codes are placed into blank envelopes.
3. A comitee validates that the envelopes are shuffled to ensure randomness.
4. Each envelope is labeled with the name and address of an eligible voter, with no one knowing which code is inside.
5. The envelopes are distributed to the voters, who use then the code to register.
6. An ETH address is generated. A private key is generated and securely stored, encrypted, on their phone.
7. A funding API endpoint instructs the system to provide base currency (used for transaction fees) and authorizes the address to participate in voting.
8. Afterward, all smart contract functions, such as voting and unvoting, become available to that particular address
9. In case some participants are not allowed to vote anymore they should personally present the phone to the comitte so they can be blocked.
10. In case new voting participants are added, they should be in batches so the shuffling of codes is done correctly and the allow function in the smart contract is not linked to any of them.
11. If 9. or 10. cannot be done and having those extra votes counted is of greater importance then all the procedures must be done from the start hence this is a system that works best for small/medium communities.

### Entities in e-Voting System

### A generic e-voting scheme involves the following entities:

- Voter: Individuals who are eligible to vote for candidates. Here each individual manages (with a help of an open source app) it's own private key
- Candidate: Nominees seeking to be considered in the election. Represented by proposals
- Registrar: Registrars are responsible for authenticating the voters. Represented by procedures & opensource
- Authority: Persons in charge of conducting the election. Represented by smart contracts
- Auditor: Authorised persons to verify and review election results. Since it's open source, anyone can audit it
- Adversary: Malicious individuals attempt to corrupt elections. There are two main types of adversaries, external and internal [5]. External adversaries, also known as coercers, actively coerce voters to vote in certain ways, whereas internal adversaries attempt to breach the system and corrupt voter privacy and authority. - Unless someone can have physical access to the voters smartphone (it's private key) it would be very difficult to corrupt the system.

### Functional Requirements

Functional requirements define the desired end functions and features required by a system. The functional requirements can be directly observed and tested.

Robustness: Any dishonest party cannot disrupt elections. ** VERIFIED **
Fairness: No partial tally is revealed. ** NOT VERIFIED **
Verifiability: The election results cannot be falsified. There are two types of verifiability: ** VERIFIED **
Individual verifiability: The voter can verify whether their vote is included in the final tally. ** VERIFIED **
Universal verifiability: All valid votes are included in the final tally and this is publicly verifiable. ** VERIFIED **
Soundness, completeness and correctness: The final tally included all valid ballots. ** VERIFIED **
Eligibility: Unqualified voters are not allowed to vote. ** VERIFIED **
Dispute-freeness: Any party can publicly verify whether the participant follows the protocol at any phase of the election. ** VERIFIED **
Transparency: Maximise transparency in the vote casting, vote storing and vote counting process while preserving the secrecy of the ballots. ** VERIFIED ** with an emphasis that procedures must be stricly respected
Accuracy: The system is errorless and valid votes must be correctly recorded and counted. This properties can be retained by universal verifiability. ** VERIFIED **
Accountability: If the vote verification process fails, the voter can prove that he has voted and at the same time preserving vote secrecy. ** NOT VERIFIED **
Practicality: The implementation of requirements and assumptions should be able to adapt to large-scale elections. ** NOT VERIFIED **
Scalability: The proposed e-voting scheme should be versatile in terms of computation, communication and storage. ** VERIFIED **

### Security Requirements

Privacy and vote secrecy: The cast votes are anonymous to any party. ** VERIFIED ** PROCEDURES STRICLY RESPECTED
Double-voting prevention, unicity and unreusability: Eligible voters cannot vote more than once. ** VERIFIED **
Receipt-freeness: The voter cannot attain any information that can be used to prove how he voted for any party. ** VERIFIED **
Coercion-resistance: Coercers cannot insist that voters vote in a certain way and the voter cannot prove his vote to the information buyer. ** PARTIALY VERIFIED **
Anonymity: The identity of the voter remains anonymous. ** VERIFIED **
Authentication: Only eligible voters were allowed to vote. ** VERIFIED **
Integrity: The system can detect the dishonest party that modifies the election results. ** VERIFIED **
Unlinkability: The voter and his vote cannot be linked. ** PARTIALY VERIFIED **

## Need help? Contact me in telegram: andyxyz1

## Build / Compile / Deploy

see Foundry:
https://book.getfoundry.sh/

## Licence: MIT
