<!-- 
// Copyright 2022 Pense Technologies.
// This file is part of Seers.

// Seers is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// Seers is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with Seers.  If not, see <http://www.gnu.org/licenses/>.
 -->
<script lang="ts">
  import DisplayButton from "../DisplayButton.svelte"

  export let auth
  export let principal
  export let signIn
  export let onSubmit
  export let managed = false
  export let description = ""
  export let sendBet = false

  let processing = false
  let errorResponse = ""
  let amount = "10"
  let collateralSelected = "seers"
  let authorChoice = ""
  let otherChoice = ""

  $: if (sendBet) {
    ;(async function () {
      const outcomes = [authorChoice, otherChoice]
      const collateralType = { [collateralSelected]: null }
      const authorChoiceNum = 0
      await onSubmit(
        description,
        outcomes,
        authorChoiceNum,
        collateralType,
        Number(amount),
      )
      description = ""
      authorChoice = ""
      otherChoice = ""
      amount = "0.0"
    })()
  }
</script>

<div
  style="display:flex; flex-direction: column; height:fit-content;border: 0px solid rgb(47, 51,54); border-radius: 16px; align-items: flex-end; padding: 5px; margin: 5px; gap: 10px;"
>
  {#if !managed}
    <textarea
      bind:value={description}
      rows="2"
      onfocus="this.style.height = '1px'; this.style.height = (25 + this.scrollHeight) + 'px'"
      onkeyup="this.style.height = '1px'; this.style.height = (25 + this.scrollHeight) + 'px'"
      placeholder={"Ask a question..."}
      class="action-textarea"
    />
  {/if}
  <div class="input-container">
    <input
      bind:value={authorChoice}
      type="text"
      placeholder={"Your Outcome"}
      class="input"
    />
  </div>
  <div class="input-container">
    <input
      bind:value={otherChoice}
      type="text"
      placeholder={"Other Outcome"}
      class="input"
    />
  </div>
  <div class="input-container">
    <div style="color:grey; padding: 0px 5px;font-size: 1.1em;">
      Bet Amount:
    </div>
    <div
      style="width: 80px; text-align:center; display:flex; justify-content:center"
    >
      <input type="text" id="start" bind:value={amount} />
    </div>
    <div class="centered">
      <select bind:value={collateralSelected} class="select">
        <option value="icp">ICP</option>
        <option value="seers">Seers</option>
      </select>
    </div>
  </div>
  {#if !managed}
    <div class="right-container">
      <DisplayButton
        {principal}
        label="Submit"
        {signIn}
        execute={async () => {
          processing = true
          const outcomes = [authorChoice, otherChoice]
          const collateralType = { [collateralSelected]: null }
          const authorChoiceNum = 0
          await onSubmit(
            description,
            outcomes,
            authorChoiceNum,
            collateralType,
            Number(amount),
          )
          processing = false
          description = ""
          authorChoice = ""
          otherChoice = ""
          amount = "0.0"
        }}
        {processing}
      />
    </div>
  {/if}
  <div class="error-container">
    {errorResponse}
  </div>
</div>
