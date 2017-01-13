import React, { PropTypes } from 'react'
import DatePicker from 'material-ui/DatePicker'
import getMuiTheme from 'material-ui/styles/getMuiTheme'
import AutoComplete from 'material-ui/AutoComplete'
import { fetchCustomers } from '../actions'
import TextField from 'material-ui/TextField'
import { connect } from 'react-redux'
import { List, ListItem } from 'material-ui/List'
import Dialog from 'material-ui/Dialog'
import FlatButton from 'material-ui/FlatButton'
import Subheader from 'material-ui/Subheader'
class AddCampaign extends React.Component {
  onEditCampaign() {

  }
  onFilterCustomers(filterText) {
    this.store.dispatch(fetchCustomers(filterText)).then(() =>
      console.log('fetchCustomers')
    )
  }
  onAddCampaign(campaign) {
    // should call server, add the product and dispatch that product
    if (campaign.Id) {
      // dispatch(editCampaign(campaign))
    } else {
      /* var campaign = {...campaign, "CreatedDate": new Date(), "Id": uuid.v4(), "PriceDate": new Date() }
      dispatch(addCampaign(campaign)) */
    }
  }
  getChildContext() {
    return { muiTheme: getMuiTheme() }
  }
  buildList() {
    return this.props.customers.map((c) => {
      return this.traverse(c)
    })
  }
  traverse(customer) {
    if (customer.children.length > 0) {
      return customer.children.map((c, i) => {
        return (<ListItem key={c.id} onNestedListToggle={(item) => { this.listItemToggle(item, c) } } primaryText={c.name} nestedItems={this.traverse(c)} />)
      })
    }
  }
  listItemToggle(item, customer) {
    item.nestedItems = []
    item.nestedItems = customer.children.filter(c => {
      return (<ListItem key={c.id} onNestedListToggle={(item) => { this.listItemToggle(item, c) } } primaryText={c.name} nestedItems={[undefined]} />)
    })
  }
  render() {
    const list = this.buildList()
    const actions = [
      <FlatButton
        label="Cancel"
        primary={true}
        onTouchTap={this.props.onClose}
        />,
      <FlatButton
        label="Save"
        primary={true}
        disabled={true}
        onTouchTap={this.props.onClose}
        />
    ]

    return (
      <div>
        <Dialog
          title={this.props.isEdit ? 'Edit campaign (' + this.props.campaign.name + ')' : 'Add campaign'}
          actions={actions}
          modal={true}
          open={this.props.isOpen}
          >
          <div><TextField floatingLabelText="Name" value={this.props.campaign.name} type="text" onChange={(e) => { this.onEditCampaign(e.target.value, 'name') } } /></div>
          <div>
            <List>
              <Subheader>Customer</Subheader>
              {list}
            </List>
          </div>
          <div><DatePicker onChange={(e, date) => { this.onEditCampaign(date, 'from') } } floatingLabelText="From" container="inline" mode="landscape" /></div>
          <div><DatePicker onChange={(e, date) => { this.onEditCampaign(date, 'to') } } floatingLabelText="To" container="inline" mode="landscape" /></div>
          <div><AutoComplete dataSourceConfig={{ text: 'text', value: 'id' }} dataSource={[{ text: '', id: '' }]} floatingLabelText="Products" filter={(searchText, key) => { return key.indexOf(searchText) > -1 } } /></div>
          <div><TextField floatingLabelText="Delivery" value={this.props.campaign.delivery} type="text" onChange={(e) => { this.onEditCampaign(e.target.value, 'delivery') } } /></div>
          <div><DatePicker onChange={(e, date) => { this.onEditCampaign(date, 'priceDate') } } hintText="PriceDate" container="inline" mode="landscape" /></div>
          <div><TextField floatingLabelText="Status" value={this.props.campaign.status} type="text" onChange={(e) => { this.onEditCampaign(e.target.value, 'status') } } /></div>
          { /* <RaisedButton onClick={(e) => { this.props.onAddCampaign(this.props.campaign) } }>Ok</RaisedButton> */}
        </Dialog>
      </div>
    )
  }
}
AddCampaign.contextTypes = {
  store: PropTypes.object.isRequired
}
AddCampaign.childContextTypes = {
  muiTheme: React.PropTypes.object.isRequired
}
/* AddCampaign.propTypes = {
          campaign: PropTypes.object.isRequired,
  customers: PropTypes.array.isRequired,
  onFilterCustomers: PropTypes.func.isRequired
} */
const mapDispatchToProps = (dispatch) => {
  return {
    onFilterCustomers: (filterText) => {
      /*dispatch(fetchCustomers(filterText)).then(() =>
        console.log('fetchCustomers')
      )*/
    }
  }
}
const mapStateToProps = (state, ownProps) => {
  return {
    campaign: ownProps.campaign || {},
    isOpen: ownProps.isOpen,
    onClose: ownProps.onClose,
    isEdit: ownProps.isEdit,
    customers: state.cmpx.customers.items || []

  }
}
export default connect(mapStateToProps, mapDispatchToProps)(AddCampaign)

