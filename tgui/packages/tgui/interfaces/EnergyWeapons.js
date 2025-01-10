import { Fragment } from 'inferno';
import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, ProgressBar, Slider } from '../components';
import { Window } from '../layouts';

export const EnergyWeapons = (props, context) => {
  const { act, data } = useBackend(context);
  const maxHealthPriority = data.maxHealthPriority;
  const regenPriority = data.regenPriority;
  const progress = data.progress;
  const chargeRate = data.chargeRate;
  const maxChargeRate = data.maxChargeRate;
  const goal = data.goal;
  const powerAlloc = data.powerAlloc;
  const maxPower = data.maxPower;
  const maxheat = data.maxheat;
  const heat = data.heat;
  const alignment = data.alignment;
  const frequency = data.frequency;
  return (
    <Window
      resizable
      theme="ntos"
      width={600}
      height={350}>
      <Window.Content scrollable>
        <Section title="Charge Status:"buttons={<Button
          fluid
          content={data.active ? "Disable Charging" : "Enable Charging"}
          icon="charging-station"
          color={data.active && "good"}
          onClick={() => act('activeToggle')} />}>
          Power Draw:
          <br />
          <ProgressBar
            value={(chargeRate / maxChargeRate * 100) * 0.01}
            ranges={{
              good: [-Infinity, 0.30],
              average: [0.30, 0.50],
              bad: [0.50, Infinity],
            }}>
            {(chargeRate / 1e+6) + ' mW'}
          </ProgressBar>
          <br />
          Heat:
          <ProgressBar
            value={(heat / maxheat)}
            ranges={{
              good: [-Infinity, 0.2],
              average: [0.2, 0.5],
              bad: [0.5, Infinity],
            }} />
          <Button
            width="150px"
            content="Vent Heat"
            icon="exclamation-triangle"
            color={"bad"}
            onClick={() => act('vent')} />
          Charge:
          <br />
          <ProgressBar
            value={(progress / goal * 100) * 0.01}
            ranges={{
              good: [0.50, Infinity],
              average: [0.15, 0.50],
              bad: [-Infinity, 0.15],
            }} />
        </Section>
        <Section title="Lens Alignment:">
          <ProgressBar
            value={data.alignment* 0.01}
            ranges={{
              good: [0.5, Infinity],
              average: [0.15, 0.5],
              bad: [-Infinity, 0.15],
            }} />
        </Section>
        <Section title="Frequency Alignment:">
          <ProgressBar
            value={data.frequency* 0.01}
            ranges={{
              good: [0.5, Infinity],
              average: [0.15, 0.5],
              bad: [-Infinity, 0.15],
            }} />
        </Section>
        <Section title="Settings:">
          Power Input Level:
          <Slider
            value={powerAlloc}
            minValue={0}
            maxValue={maxPower}
            step={0.5}
            stepPixelSize={5}
            onDrag={(e, value) => act('power', {
              input: value,
            })} />
        </Section>
      </Window.Content>
    </Window>
  );
};
