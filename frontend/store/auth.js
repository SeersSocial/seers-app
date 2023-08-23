import { writable } from "svelte/store";
import { idlFactory } from "../../declarations/markets/markets.did.js";
import { Actor, HttpAgent } from "@dfinity/agent";

/**
 * Creates an actor for the Backend canister
 *
 * @param {{agentOptions: import("@dfinity/agent").HttpAgentOptions, actorOptions: import("@dfinity/agent").ActorConfig}} options
 * @returns {import("@dfinity/agent").ActorSubclass<import("../../declarations/markets/markets.did")._SERVICE>}
 */
export function createActor(options) {
  const hostOptions = {
    // host: 'http://localhost:8000',
    host:`https://${process.env.MARKETS_CANISTER_ID}.ic0.app`,
  };
  if (!options) {
    options = {
      agentOptions: hostOptions,
    };
  } else if (!options.agentOptions) {
    options.agentOptions = hostOptions;
  } else {
    options.agentOptions.host = hostOptions.host;
  }

  const agent = new HttpAgent({ ...options.agentOptions });

  // Fetch root key for certificate validation during development
  // if (process.env.NODE_ENV !== "production") {
    // agent.fetchRootKey().catch((err) => {
    //   console.warn(
    //     "Unable to fetch root key. Check to ensure that your local replica is running"
    //   );
    //   console.error(err);
    // });
  // }

  // Creates an actor with using the candid interface and the HttpAgent
  return Actor.createActor(idlFactory, {
    agent,
    canisterId: process.env.MARKETS_CANISTER_ID,
    ...options?.actorOptions,
  });
}

export const auth = writable({
  loggedIn: false,
  actor: createActor(),
});
