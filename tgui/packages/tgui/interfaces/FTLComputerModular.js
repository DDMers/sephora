import { Fragment } from 'inferno';
import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, ProgressBar, Table } from '../components';
import { Window } from '../layouts';

export const FTLComputerModular = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Window
      resizable
      theme={data.await_emergency_ftl_confirm ? "malfunction" : "hackerman"}
      width={600}
      height={550}>
      <Window.Content scrollable>
        {(data.await_emergency_ftl_confirm && (
          <Section>
            <Section
              title="OVERRIDE">
              <Button
                icon="exclamation-triangle"
                fluid
                color="red"
                onClick={() => act('emergency_jump')}
                content="CONFIRM EMERGENCY JUMP?"
              />
            </Section>
          </Section>
        )) || (
          <Section>
            <Section title="Pylon control:">
              <Table.Row fluid>
                {Object.keys(data.pylons).map(key => {
                  let value = data.pylons[key];
                  return (
                    <Table.Cell key={key}>
                      <Section title={`${value.name}`}>
                        <Button
                          content="Toggle Power"
                          icon="power-off"
                          color={value.status === "shutdown" ? "average" : value.status === "offline" ? "bad" : "good"}
                          disabled={value.status === "shutdown"}
                          onClick={() => act('pylon_power', { id: value.id })} />
                        <Button
                          content={value.shielded ? "Open Shield" : "Close Shield"}
                          icon="exclamation-triangle"
                          color={value.shielded && "average"}
                          onClick={() => act('toggle_shield', { id: value.id })} />
                        <br />
                        Cycle Status: <b>{value.status}</b>
                        <br />
                        <br />
                        Gyro Speed:
                        <ProgressBar
                          value={value.gyro}
                          ranges={{
                            good: [1, 2],
                            average: [0.5, 0.99],
                            bad: [0, 0.49],
                          }} />
                        <br />
                        Capacitor Charge:
                        <ProgressBar
                          value={value.capacitor}
                          ranges={{
                            good: [1, 2],
                            average: [0.5, 0.99],
                            bad: [0, 0.49],
                          }} />
                        <br />
                        Power Draw: <b>{value.draw}</b>
                        <br />
                        Nucleium: <b>{value.nucleium}</b> mol{value.nucleium !== 1 ? "s" : ""} / s
                      </Section>
                    </Table.Cell>);
                })}
              </Table.Row>
              <Button
                content="Find Pylons"
                icon="search"
                onClick={() => act('find_pylons')} />

            </Section>
            <Section
              title="Manifold controls:">
              <Button
                color={!!data.powered && 'green'}
                disabled={data.jumping || !data.pylons.length}
                content={data.progress ? "Shutdown Drive" : "Spool Drive"}
                onClick={() => act('toggle_power')} />
              <Button
                color={!!data.auto_spool_enabled && 'green'}
                disabled={!data.can_auto_spool}
                content={data.auto_spool_enabled ? "Disable Autospool" : "Enable Autospool"}
                onClick={() => act('toggle_autospool')} />
            </Section>
            <Section title="FTL Spoolup:">
              <ProgressBar
                value={data.progress/data.goal}
                ranges={{
                  good: [0.95, Infinity],
                  average: [0.15, 0.95],
                  bad: [-Infinity, 0.15],

                }} />
            </Section>
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};
