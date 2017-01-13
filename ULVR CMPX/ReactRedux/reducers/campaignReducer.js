
function campaignsReducer(state = {}, action) {
  return {
    ...state,
    items: state.items.map(p => {
      return campaignReducer(p, action)
    })
  }
}

function campaignReducer(state = {}, action) {
  switch (action.type) {
    default:
      return state
  }
}
export default campaignsReducer
