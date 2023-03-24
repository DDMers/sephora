// NSV13

import { Fragment } from 'inferno';
import { useBackend, useLocalState } from '../backend';
import { Box, Button, LabeledList, NumberInput, Section, Table, Input } from '../components';
import { Window } from '../layouts';
import { createSearch } from 'common/string';

export const StarsystemManager = (props, context) => {
  const { act, data } = useBackend(context);

  const [
    searchText,
    setSearchText,
  ] = useLocalState(context, 'searchText', '');

  const Search = createSearch(searchText, item => {
    return item;
  });

  const makeFleetButton = fleet => {
    return (
      <Button key={fleet}
        content={fleet.name}
        icon="space-shuttle"
        color={fleet.color}
        onClick={() => act('fleetAct', { id: fleet.id })} />
    );
  };

  const makeObjectButton = thing => {
    return (
      <Button key={thing}
        content={thing.name}
        icon="space-shuttle"
        color={thing.color}
        onClick={() => act('objectAct', { id: thing.id })} />
    );
  };

  const makeSystem = system => {
    let Fleets = (system.fleets).map(makeFleetButton);
    let OtherObjects = (system.objects).map(makeObjectButton);
    return (
      <Section title={`${system.name}`} buttons={
        <Fragment>
          <Button
            content={"Send Fleet"}
            icon={"hammer"}
            onClick={() => act('createFleet', { sys_id: system.sys_id })} />
          <Button
            content={"Create object"}
            icon={"sun"}
            onClick={() => act('createObject', { sys_id: system.sys_id })} />
          <Button
            content={"Variables"}
            icon="eye"
            onClick={() => act('systemVV', { sys_id: system.sys_id })} />
        </Fragment>
      }>
        Alignment: {system.alignment}<br />
        System Type: {system.system_type}<br />
        <br />
        {Fleets}
        {OtherObjects}
      </Section>
    );
  };

  const Header = (
    <Section
      title={
        <Table>
          <Table.Row>
            <Table.Cell>
              {"Starsystem Management"}
            </Table.Cell>
            <Table.Cell
              textAlign="right">
              <Input
                placeholder="Search"
                value={searchText}
                onInput={(e, value) => setSearchText(value)}
                mx={1}
              />
            </Table.Cell>
          </Table.Row>
        </Table>
      } />
  );

  let searchSystems = (data.systems_info).filter(system => Search(system.name)).map(makeSystem);
  let searchObjects = (data.systems_info).filter(system => system.objects.some(obj => Search(obj.name))).map(makeSystem);
  let searchFleets = (data.systems_info).filter(system => system.fleets.some(obj => Search(obj.name))).map(makeSystem);
  let Systems = searchSystems.concat(searchObjects.concat(searchFleets));
  return (
    <Window
      resizable
      theme="ntos"
      width={600}
      height={600}>
      <Window.Content scrollable>
        {Header}
        <Section>
          {Systems}
        </Section>
      </Window.Content>
    </Window>
  );
};
