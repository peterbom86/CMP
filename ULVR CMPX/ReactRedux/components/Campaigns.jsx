import React, { PropTypes } from 'react'
import moment from 'moment'
import getMuiTheme from 'material-ui/styles/getMuiTheme'
import { connect } from 'react-redux'
import AddCampaign from './AddCampaign'
import { editCampaign, fetchCampaigns } from '../actions'
import { TextField } from 'material-ui'
import {debounce} from 'lodash'

import { Table, TableBody, TableHeader, TableHeaderColumn, TableRow, TableRowColumn } from 'material-ui/Table'

class Campaigns extends React.Component {

  constructor() {
    super()
    this.onFilterCampaigns = debounce(this.onFilterCampaigns, 100)
  }

  getChildContext() {
    return { muiTheme: getMuiTheme() }
  }

  onFilterCampaigns(text) {
    if (text !== '') {
      this.props.onSearchTextChange(text)
    }
  }

  render() {
    const searchFoundText = this.props.totalItemCount === 0 ? 'Seach campaigns' : 'Seach campaigns (' + this.props.totalItemCount + ' found)'
    return (
      <div>
        <div>
          <TextField floatingLabelText={searchFoundText} onChange={(e) => { this.onFilterCampaigns(e.target.value) } } />
        </div>
        <Table selectable={false} height='100px'>
          <TableHeader adjustForCheckbox={false} displaySelectAll={false} s>
            <TableRow>
              <TableHeaderColumn>Name</TableHeaderColumn>
              <TableHeaderColumn>Customer</TableHeaderColumn>
              <TableHeaderColumn>Start Date</TableHeaderColumn>
              <TableHeaderColumn>End Date</TableHeaderColumn>
              <TableHeaderColumn>Price Date</TableHeaderColumn>

              <TableHeaderColumn></TableHeaderColumn>
            </TableRow>
          </TableHeader>
          <TableBody displayRowCheckbox={false}>

            {this.props.campaigns.map((c, i) => {
              return (
                <TableRow key={i}>
                  <TableRowColumn>
                    {c.name}
                  </TableRowColumn>
                  <TableRowColumn>
                    {c.customerName}
                  </TableRowColumn>
                  <TableRowColumn>
                    {moment(c.startDate).format('YYYY-MM-DD')}
                  </TableRowColumn>
                  <TableRowColumn>
                    {moment(c.endDate).format('YYYY-MM-DD')}
                  </TableRowColumn>
                  <TableRowColumn>
                    {moment(c.priceDate).format('YYYY-MM-DD')}
                  </TableRowColumn>
                  <TableRowColumn>
                    <a href="javascript:void(0)" onClick={(e) => { this.props.onEditCampaign(c) } } >Edit</a><span>&nbsp;|&nbsp;</span>
                    <a href="javascript:void(0)" onClick={(e) => { } } >Details</a><span>&nbsp;|&nbsp;</span>
                    <a href="javascript:void(0)" onClick={(e) => { } } >Delete</a>
                  </TableRowColumn>
                </TableRow>
              )
            })
            }
          </TableBody>
        </Table>
        <hr />
        <AddCampaign
          isEdit={true}
          onClose={(e) => { this.props.onEditCampaign(null) } }
          isOpen={this.props.selectedCampaign != null}
          campaign={this.props.selectedCampaign}
          />
      </div>
    )
  }
}
Campaigns.contextTypes = {
  store: PropTypes.object.isRequired
}
Campaigns.childContextTypes = {
  muiTheme: React.PropTypes.object.isRequired
}
const mapDispatchToProps = (dispatch) => {
  return {
    onEditCampaign: (campaign) => {
      dispatch(editCampaign(campaign))
    },
    onSearchTextChange: (text) => {
      dispatch(fetchCampaigns(text))
    }
  }
}

const mapStateToProps = (state) => {
  return {
    campaigns: state.cmpx.campaigns.items,
    totalItemCount: state.cmpx.campaigns.meta.totalItemCount,
    selectedCampaign: state.cmpx.selectedCampaign
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(Campaigns)
