export type TrackingData = {
  carbon: Trackable[];
  simple_mob: Trackable[];
};

export type Trackable = {
  role_icon?: string ;
  name?: string;
  ref: string;
};
