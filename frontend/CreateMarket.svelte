<script>
  export let auth
  export let principal
  export let signIn

  let labels = "Yes,No"
  let images = ""
  let marketCreated = false
  let newMarketTitle = ""
  let newMarketDesc = ""
  let startDate = "June 15, 2022 23:00:00"
  let endDate = "February 15, 2021 23:00:00"
  let imageUrl = ""
  let buttonLabel = "Create"
  let errorResponse = ""
  let createResult = null
  let categorySelected

  const splitCamelCaseToString = (s) => {
    return s
      .split(/(?=[A-Z])/)
      .map((p) => {
        return p[0].toUpperCase() + p.slice(1)
      })
      .join(" ")
  }

  let createMarket = async () => {
    const liquidity = 1000
    let probabilities = []
    let i = 0

    let labelsA = labels.split(",").map((s) => s.trim())
    let imagesA = images.split(",").map((s) => s.trim())

    for (; i < labelsA.length; i++) {
      probabilities.push(1.0 / labelsA.length)
    }

    let category = {}
    category[categorySelected] = null
    const marketInitData = {
      id: 0,
      title: newMarketTitle,
      description: newMarketDesc,
      labels: labelsA,
      images: imagesA,
      probabilities: probabilities,
      category: category,
      liquidity: liquidity,
      startDate: Date.parse(startDate) * 1_000_000,
      endDate: Date.parse(endDate) * 1_000_000,
      imageUrl: imageUrl,
      collateralType: { seers: null },
      author: "",
    }
    buttonLabel = "Processing..."
    createResult = await $auth.actor.createMarket(marketInitData)

    if (createResult["err"]) {
      errorResponse =
        "Error: " +
        splitCamelCaseToString(Object.keys(createResult["err"]).toString())
      buttonLabel = "Create"
    } else {
      buttonLabel = "Create"
      marketCreated = true
    }
  }
</script>

{#if marketCreated}
  <div class="header">
    <h3>Market created and waiting for approval!</h3>
  </div>
  <div class="rowCreate" />
{:else}
  <div class="header">
    <h3>Create Market</h3>
  </div>

  <div class="rowCreate">
    <div class="form">
      <div style="width: 80%; padding: 1em; text-align:left; font-size: 0.7em">
        <div style="font-size: 1.5em">Title:</div>
        <div>
          <input bind:value={newMarketTitle} size="40" maxlength="200" />
        </div>
      </div>
      <div style="width: 80%; padding: 1em; text-align:left; font-size: 0.7em">
        <div style="font-size: 1.5em">Description:</div>
        <div><textarea bind:value={newMarketDesc} rows="20" cols="40" /></div>
      </div>
      <div style="width: 80%; padding: 1em; text-align:left; font-size: 0.7em">
        <div style="font-size: 1.5em">Image link:</div>
        <div><input bind:value={imageUrl} size="40" maxlength="200" /></div>
      </div>
      <div style="width: 80%; padding: 1em; text-align:left; font-size: 0.7em">
        <div style="font-size: 1.5em">Image Preview:</div>
        <div><img src={imageUrl} alt="preview" style="width: 100px" /></div>
      </div>
      <div style="width: 80%; padding: 1em; text-align:left; font-size: 0.7em">
        <div style="font-size: 1.5em">Outcomes:</div>
        <div style="font-size: 1.5em">
          <input bind:value={labels} size="40" maxlength="1000" />
        </div>
      </div>
      <div style="width: 80%;padding: 1em; text-align:left; font-size: 0.7em">
        <div style="font-size: 1.5em">End date:</div>
        <div><input bind:value={endDate} size="20" maxlength="30" /></div>
      </div>
      <div style="width: 80%;padding: 1em; text-align:left; font-size: 0.7em">
        <div style="font-size: 1.5em">Category:</div>
        <select
          bind:value={categorySelected}
          style="background: white; color: black; width: 200px;"
        >
          <option value="crypto">Crypto</option>
          <option value="sports">Sports</option>
          <option value="politics">Politics</option>
          <option value="entertainment">Entertainment</option>
          <option value="science">Science</option>
          <option value="business">Business</option>
          <option value="finance">Finance</option>
          <option value="seers">Seers</option>
          <option value="dfinity">Internet Computer</option>
          <option value="self">Self Referential</option>
        </select>
      </div>
      {#if principal !== ""}
        <div style="width: 100%;text-align:center; ">
          <button class="btn-grad" on:click={createMarket}>{buttonLabel}</button
          >
        </div>
      {:else}
        <div style="width: 100%;text-align:center; ">
          <button class="btn-grad" on:click={signIn} style="background:black"
            >Please login</button
          >
        </div>
      {/if}
      <div style="width: 100%;text-align:center;color:red">
        {errorResponse}
      </div>
    </div>
  </div>
{/if}

<style global>
  input {
    line-height: 20px;
  }
  .rowCreate {
    display: flex;
    flex-direction: column;
    flex-wrap: wrap;
    padding: 0 4px;
    justify-content: center;
    align-items: center;
    align-content: center;
  }

  .form {
    display: flex;
    flex-direction: column;
    flex-wrap: wrap;
    padding: 30px;
    justify-content: center;
    width: 500px;

    background-color: black;
    border: 1px solid rgb(61, 60, 61);
    box-shadow: 2px 2px 20px 0.5px rgb(54, 27, 46);

    /* border: 2px solid rgb(25, 27, 31); */
    border-radius: 16px;
    color: rgb(255, 255, 255);
    /*     
    border-radius: 5px;
    background: rgb(220 218 224 / 10%); */
  }
</style>
