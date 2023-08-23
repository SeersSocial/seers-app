import { writable } from 'svelte/store';

export const modal = writable(null);
export const windowStyle = writable({});
export const pageType = writable(0); // 0 feed, 1 post, 2 user
export const userToView = writable(null);
export const postToView = writable(null);
export const feedStore = writable([]);
export const loggedUser = writable(null)
export const userMap = writable(null)

export async function setUserMapStore(auth) {
    try {
        // console.log("executing read all users")
        // let users = await auth.actor.readAllUsers()
        // let um = {}
        // for (const u of users) {
        //     um[u['v4'].handle] = u['v4']    
        // }
        // userMap.set(um)
    } catch (e) {
        // console.log(e)
    }
}